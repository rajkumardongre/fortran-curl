! http.f90
!
! Basic HTTP client in Fortran, using libcurl.
!
! Author:  Philipp Engel
! Licence: ISC
module http_callback
    use, intrinsic :: iso_fortran_env, only: i8 => int64
    use :: curl, only: c_f_str_ptr
    implicit none
    private
    public :: response_callback

    type, public :: response_type
        character(len=:), allocatable :: content
    end type response_type
contains
    ! static size_t callback(char *ptr, size_t size, size_t nmemb, void *data)
    function response_callback(ptr, size, nmemb, client_data) bind(c)
        !! Callback function for `CURLOPT_WRITEFUNCTION` that appends the
        !! response chunk `ptr` to the given `data` of type `response_type`.
        !!
        !! This callback function might be called several times by libcurl,
        !! passing in more chunks of the response.
        use, intrinsic :: iso_c_binding, only: c_associated, c_f_pointer, c_ptr, c_size_t
        type(c_ptr),            intent(in), value :: ptr               !! C pointer to a chunk of the response.
        integer(kind=c_size_t), intent(in), value :: size              !! Always 1.
        integer(kind=c_size_t), intent(in), value :: nmemb             !! Size of the response chunk.
        type(c_ptr),            intent(in), value :: client_data       !! C pointer to argument passed by caller.
        integer(kind=c_size_t)                    :: response_callback !! Function return value.

        type(response_type), pointer  :: response
        character(len=:), allocatable :: buf

        response_callback = int(0, kind=c_size_t)

        ! Are the passed C pointers associated?
        if (.not. c_associated(ptr)) return
        if (.not. c_associated(client_data)) return

        ! Convert C pointer to Fortran pointer.
        call c_f_pointer(client_data, response)
        if (.not. allocated(response%content)) response%content = ''

        ! Convert C pointer to Fortran allocatable character.
        call c_f_str_ptr(ptr, buf, nmemb)
        if (.not. allocated(buf)) return
        response%content = response%content // buf
        deallocate (buf)

        ! Return number of received bytes.
        response_callback = nmemb
    end function response_callback
end module http_callback

program main
    use, intrinsic :: iso_c_binding
    use, intrinsic :: iso_fortran_env, only: i8 => int64
    use :: curl
    use :: http_callback
    implicit none

    character(len=*), parameter :: DEFAULT_PROTOCOL = 'http'
    character(len=*), parameter :: DEFAULT_URL      = 'http://worldtimeapi.org/api/timezone/Europe/London.txt'

    type(c_ptr)                 :: curl_ptr
    integer                     :: rc
    type(response_type), target :: response

    curl_ptr = curl_easy_init()

    if (.not. c_associated(curl_ptr)) then
        stop 'Error: curl_easy_init() failed'
    end if

    ! Set curl options.
    rc = curl_easy_setopt(curl_ptr, CURLOPT_DEFAULT_PROTOCOL, DEFAULT_PROTOCOL)
    rc = curl_easy_setopt(curl_ptr, CURLOPT_URL,              DEFAULT_URL)
    rc = curl_easy_setopt(curl_ptr, CURLOPT_FOLLOWLOCATION,   1)
    rc = curl_easy_setopt(curl_ptr, CURLOPT_TIMEOUT,          10)
    rc = curl_easy_setopt(curl_ptr, CURLOPT_NOSIGNAL,         1)
    rc = curl_easy_setopt(curl_ptr, CURLOPT_CONNECTTIMEOUT,   10)
    rc = curl_easy_setopt(curl_ptr, CURLOPT_WRITEFUNCTION,    c_funloc(response_callback))
    rc = curl_easy_setopt(curl_ptr, CURLOPT_WRITEDATA,        c_loc(response))

    ! Send request.
    rc = curl_easy_perform(curl_ptr)
    call curl_easy_cleanup(curl_ptr)

    if (rc /= CURLE_OK) stop 'Error: curl_easy_perform() failed'

    ! Output response.
    if (.not. allocated(response%content)) stop 'Error: no response data'
    print '(a)', response%content
end program main
