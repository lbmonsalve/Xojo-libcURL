#tag Class
Protected Class MultipartForm
Inherits libcURL.cURLHandle
Implements FormStreamGetter
	#tag Method, Flags = &h0
		Function AddElement(Name As String, Value As FolderItem, ContentType As String = "", AdditionalHeaders As libcURL.ListPtr = Nil) As Boolean
		  ' Adds the passed file to the form using the specified name.
		  ' See:
		  ' http://curl.haxx.se/libcurl/c/curl_formadd.html
		  ' https://github.com/charonn0/RB-libcURL/wiki/libcURL.MultipartForm.AddElement
		  
		  If Value.Exists And Not Value.Directory Then
		    If ContentType = "" Then ContentType = MimeType(Value)
		    Dim headeropt As Integer = CURLFORM_END
		    If AdditionalHeaders <> Nil Then
		      headeropt = CURLFORM_CONTENTHEADER
		      If mAdditionalHeaders.IndexOf(AdditionalHeaders) = -1 Then mAdditionalHeaders.Append(AdditionalHeaders)
		    End If
		    If ContentType <> "" Then
		      Return FormAdd(CURLFORM_COPYNAME, Name, CURLFORM_FILE, Value.ShellPath, CURLFORM_FILENAME, Value.Name, CURLFORM_CONTENTTYPE, ContentType, headeropt, AdditionalHeaders)
		    Else
		      Return FormAdd(CURLFORM_COPYNAME, Name, CURLFORM_FILE, Value.ShellPath, CURLFORM_FILENAME, Value.Name, headeropt, AdditionalHeaders)
		    End If
		  Else
		    mLastError = libcURL.Errors.INVALID_LOCAL_FILE
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function AddElement(Name As String, ByRef Value As MemoryBlock, Filename As String, ContentType As String = "", AdditionalHeaders As libcURL.ListPtr = Nil) As Boolean
		  ' Adds the passed buffer to the form as a file part using the specified name. The buffer pointed to by Value
		  ' is used directly (i.e. not copied) so it must continue to exist until after the POST request has completed.
		  ' This method allows file parts to be added without using an actual file. Specify an empty Filename parameter
		  ' to add the Value as a non-file form part.
		  '
		  ' See:
		  ' http://curl.haxx.se/libcurl/c/curl_formadd.html
		  ' https://github.com/charonn0/RB-libcURL/wiki/libcURL.MultipartForm.AddElement
		  
		  If Value Is Nil Then Raise New NilObjectException
		  If Value.Size < 0 Then Raise New OutOfBoundsException
		  
		  Dim v() As Variant
		  Dim o() As Integer
		  o.Append(CURLFORM_COPYNAME)
		  v.Append(Name)
		  o.Append(CURLFORM_BUFFERPTR)
		  v.Append(Value)
		  If Filename.Trim <> "" Then
		    o.Append(CURLFORM_BUFFER)
		    v.Append(Filename)
		  End If
		  o.Append(CURLFORM_BUFFERLENGTH)
		  v.Append(Value.Size)
		  
		  If ContentType.Trim <> "" Then
		    o.Append(CURLFORM_CONTENTTYPE)
		    v.Append(ContentType)
		  End If
		  
		  If AdditionalHeaders <> Nil Then
		    o.Append(CURLFORM_CONTENTHEADER)
		    v.Append(AdditionalHeaders)
		    If mAdditionalHeaders.IndexOf(AdditionalHeaders) = -1 Then mAdditionalHeaders.Append(AdditionalHeaders)
		  End If
		  
		  Return FormAdd(o, v)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function AddElement(Name As String, ValueStream As Readable, ValueSize As Integer, Filename As String = "", ContentType As String = "", AdditionalHeaders As libcURL.ListPtr = Nil) As Boolean
		  ' Adds an element using the specified name, with contents which will be read from the passed Readable object.
		  ' See:
		  ' http://curl.haxx.se/libcurl/c/curl_formadd.html
		  ' https://github.com/charonn0/RB-libcURL/wiki/libcURL.MultipartForm.AddElement
		  
		  Dim e As New libcURL.EasyHandle(Me.Flags)
		  e.UploadStream = ValueStream
		  mStreams.Append(e)
		  
		  Dim v() As Variant
		  Dim o() As Integer
		  
		  o.Append(CURLFORM_COPYNAME)
		  v.Append(Name)
		  o.Append(CURLFORM_STREAM)
		  v.Append(e)
		  
		  If Filename.Trim <> "" Then
		    o.Append(CURLFORM_FILENAME)
		    v.Append(Filename)
		  End If
		  
		  If ContentType.Trim <> "" Then
		    o.Append(CURLFORM_CONTENTTYPE)
		    v.Append(ContentType)
		  End If
		  
		  If AdditionalHeaders <> Nil Then
		    o.Append(CURLFORM_CONTENTHEADER)
		    v.Append(AdditionalHeaders)
		    If mAdditionalHeaders.IndexOf(AdditionalHeaders) = -1 Then mAdditionalHeaders.Append(AdditionalHeaders)
		  End If
		  
		  If ValueSize > 0 Then
		    o.Append(CURLFORM_CONTENTSLENGTH)
		    v.Append(ValueSize)
		  End If
		  
		  Return FormAdd(o, v)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function AddElement(Name As String, Value As String, AdditionalHeaders As libcURL.ListPtr = Nil) As Boolean
		  ' Adds the passed Value to the form using the specified name.
		  ' See:
		  ' http://curl.haxx.se/libcurl/c/curl_formadd.html
		  ' https://github.com/charonn0/RB-libcURL/wiki/libcURL.MultipartForm.AddElement
		  
		  If AdditionalHeaders <> Nil Then
		    If mAdditionalHeaders.IndexOf(AdditionalHeaders) = -1 Then mAdditionalHeaders.Append(AdditionalHeaders)
		    Return FormAdd(CURLFORM_COPYNAME, Name, CURLFORM_COPYCONTENTS, Value, CURLFORM_CONTENTHEADER, AdditionalHeaders)
		  Else
		    Return FormAdd(CURLFORM_COPYNAME, Name, CURLFORM_COPYCONTENTS, Value)
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(GlobalInitFlags As Integer = libcURL.CURL_GLOBAL_DEFAULT)
		  // Calling the overridden superclass constructor.
		  // Constructor(GlobalInitFlags As Integer) -- From libcURL.cURLHandle
		  Super.Constructor(GlobalInitFlags)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Count() As Integer
		  ' Returns the number of elements in the form.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libcURL/wiki/libcURL.MultipartForm.Count
		  
		  Dim e As libcURL.MultipartFormElement = Me.FirstItem
		  Dim c As Integer
		  Do Until e = Nil
		    c = c + 1
		    e = e.NextElement
		  Loop
		  Return c
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function curlFormGet(Data As MemoryBlock, Length As Integer) As Integer
		  Return RaiseEvent SerializePart(Data, Length)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Deserialize(FormData As Readable) As libcURL.MultipartForm
		  Dim data As New MemoryBlock(0)
		  Dim bs As New BinaryStream(data)
		  Do Until FormData.EOF
		    bs.Write(FormData.Read(64 * 1024))
		  Loop
		  bs.Close
		  Return Deserialize(data)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Deserialize(FormData As String) As libcURL.MultipartForm
		  Dim form As New MultipartForm
		  Dim Boundary As String = NthField(FormData, EndOfLine.Windows, 1)
		  If Left(Boundary, Len("Content-Type:")) <> "Content-Type:" Then Raise New UnsupportedFormatException
		  Boundary = NthField(Boundary, "boundary=", 2).Trim
		  Dim elements() As String = Split(FormData, "--" + Boundary)
		  
		  Dim ecount As Integer = UBound(elements)
		  For i As Integer = 1 To ecount
		    Dim line As String = NthField(elements(i).LTrim, EndOfLine.Windows, 1)
		    Dim name As String = NthField(line, ";", 2)
		    name = NthField(name, "=", 2)
		    name = ReplaceAll(name, """", "")
		    If name.Trim = "" Then Continue For i
		    If CountFields(line, ";") < 3 Then 'form field
		      If Not form.AddElement(name, NthField(elements(i), EndOfLine.Windows + EndOfLine.Windows, 2)) Then Raise New libcURL.cURLException(form)
		    Else 'file field
		      Dim filename As String = NthField(line, ";", 3)
		      filename = NthField(filename, "=", 2)
		      filename = ReplaceAll(filename, """", "")
		      Dim tmp As FolderItem = SpecialFolder.Temporary.Child(filename)
		      Dim bs As BinaryStream = BinaryStream.Create(tmp, True)
		      Dim filedata As MemoryBlock = elements(i)
		      Dim t As Integer = InStr(filedata, EndOfLine.Windows + EndOfLine.Windows) + 3
		      filedata = filedata.StringValue(t, filedata.Size - t - 2)
		      bs.Write(filedata)
		      bs.Close
		      If Not form.AddElement(name, tmp) Then Raise New libcURL.cURLException(form)
		    End If
		  Next
		  
		  Return form
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  If mHandle <> 0 Then curl_formfree(mHandle)
		  ReDim mStreams(-1)
		  ReDim mAdditionalHeaders(-1)
		  mHandle = 0
		  LastItem = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function FormAdd(Options() As Integer, Values() As Variant) As Boolean
		  If UBound(Options) <> UBound(Values) Then Raise New OutOfBoundsException
		  
		  Select Case UBound(Options)
		  Case 1
		    Return FormAdd(Options(0), Values(0), Options(1), Values(1))
		  Case 2
		    Return FormAdd(Options(0), Values(0), Options(1), Values(1), Options(2), Values(2))
		  Case 3
		    Return FormAdd(Options(0), Values(0), Options(1), Values(1), Options(2), Values(2), Options(3), Values(3))
		  Case 4
		    Return FormAdd(Options(0), Values(0), Options(1), Values(1), Options(2), Values(2), Options(3), Values(3), Options(4), Values(4))
		  Case 5
		    Return FormAdd(Options(0), Values(0), Options(1), Values(1), Options(2), Values(2), Options(3), Values(3), Options(4), Values(4), Options(5), Values(5))
		  Case 6
		    Return FormAdd(Options(0), Values(0), Options(1), Values(1), Options(2), Values(2), Options(3), Values(3), Options(4), Values(4), Options(5), Values(5), Options(6), Values(6))
		  Case 7
		    Return FormAdd(Options(0), Values(0), Options(1), Values(1), Options(2), Values(2), Options(3), Values(3), Options(4), Values(4), Options(5), Values(5), Options(6), Values(6), Options(7), Values(7))
		  Case 8
		    Return FormAdd(Options(0), Values(0), Options(1), Values(1), Options(2), Values(2), Options(3), Values(3), Options(4), Values(4), Options(5), Values(5), Options(6), Values(6), Options(7), Values(7), Options(8), Values(8))
		  Case 9
		    Return FormAdd(Options(0), Values(0), Options(1), Values(1), Options(2), Values(2), Options(3), Values(3), Options(4), Values(4), Options(5), Values(5), Options(6), Values(6), Options(7), Values(7), Options(8), Values(8), Options(9), Values(9))
		  Case 10
		    Return FormAdd(Options(0), Values(0), Options(1), Values(1), Options(2), Values(2), Options(3), Values(3), Options(4), Values(4), Options(5), Values(5), Options(6), Values(6), Options(7), Values(7), Options(8), Values(8), Options(9), Values(9), Options(10), Values(10))
		  Else
		    Raise New OutOfBoundsException
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function FormAdd(Option As Integer, Value As Variant, Option1 As Integer = CURLFORM_END, Value1 As Variant = Nil, Option2 As Integer = CURLFORM_END, Value2 As Variant = Nil, Option3 As Integer = CURLFORM_END, Value3 As Variant = Nil, Option4 As Integer = CURLFORM_END, Value4 As Variant = Nil, Option5 As Integer = CURLFORM_END, Value5 As Variant = Nil, Option6 As Integer = CURLFORM_END, Value6 As Variant = Nil, Option7 As Integer = CURLFORM_END, Value7 As Variant = Nil, Option8 As Integer = CURLFORM_END, Value8 As Variant = Nil, Option9 As Integer = CURLFORM_END, Value9 As Variant = Nil, Option10 As Integer = CURLFORM_END, Value10 As Variant = Nil) As Boolean
		  ' This helper function is a wrapper for the variadic external method curl_formadd. Since external methods
		  ' can't be variadic, this method simulates it by accepting a finite number of optional arguments.
		  '
		  ' Each form field is passed as (at least) four arguments: two Option/Value arguments each for the name and
		  ' contents of the form field. For example, a form with a username field and password field:
		  '
		  '    Call FormAdd( _
		  '      CURLFORM_COPYNAME, "username", CURLFORM_COPYCONTENTS, "Bob", _
		  '      CURLFORM_COPYNAME, "password", CURLFORM_COPYCONTENTS, "seekrit")
		  '
		  ' At least 1 and up to 11 pairs of arguments may be passed at once. Refer the to the libcURL documentation
		  ' for details.
		  '
		  ' See:
		  ' http://curl.haxx.se/libcurl/c/curl_formadd.html
		  ' https://github.com/charonn0/RB-libcURL/wiki/libcURL.MultipartForm.FormAdd
		  
		  Dim v() As Variant = Array(Value, Value1, Value2, Value3, Value4, Value5, Value6, Value7, Value8, Value9, Value10)
		  Dim m() As MemoryBlock
		  Dim o() As Integer = Array(Option, Option1, Option2, Option3, Option4, Option5, Option6, Option7, Option8, Option9, Option10)
		  For i As Integer = 0 To UBound(v)
		    Select Case VarType(v(i))
		    Case Variant.TypeNil
		      m.Append(New MemoryBlock(0))
		      
		    Case Variant.TypePtr, Variant.TypeInteger
		      m.Append(v(i).PtrValue)
		      
		    Case Variant.TypeObject
		      Select Case v(i)
		      Case IsA FolderItem
		        Dim mb As MemoryBlock = FolderItem(v(i)).AbsolutePath + Chr(0) ' make doubleplus sure it's null terminated
		        m.Append(mb)
		      Case IsA cURLHandle
		        m.Append(Ptr(cURLHandle(v(i)).Handle))
		      Case IsA MemoryBlock
		        m.Append(MemoryBlock(v(i)))
		      Else
		        Break
		      End Select
		      
		    Case Variant.TypeString
		      Dim mb As MemoryBlock = v(i).StringValue + Chr(0) ' make doubleplus sure it's null terminated
		      m.Append(mb)
		      
		    Else
		      Break
		      
		    End Select
		  Next
		  
		  Return FormAddPtr(o(0), m(0), o(1), m(1), o(2), m(2), o(3), m(3), o(4), m(4), o(5), m(5), o(6), m(6), o(7), m(7), o(8), m(8), o(9), m(9), o(10), m(10))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function FormAddPtr(Option As Integer, Value As Ptr, Option1 As Integer = CURLFORM_END, Value1 As Ptr = Nil, Option2 As Integer = CURLFORM_END, Value2 As Ptr = Nil, Option3 As Integer = CURLFORM_END, Value3 As Ptr = Nil, Option4 As Integer = CURLFORM_END, Value4 As Ptr = Nil, Option5 As Integer = CURLFORM_END, Value5 As Ptr = Nil, Option6 As Integer = CURLFORM_END, Value6 As Ptr = Nil, Option7 As Integer = CURLFORM_END, Value7 As Ptr = Nil, Option8 As Integer = CURLFORM_END, Value8 As Ptr = Nil, Option9 As Integer = CURLFORM_END, Value9 As Ptr = Nil, Option10 As Integer = CURLFORM_END, Value10 As Ptr = Nil) As Boolean
		  mLastError = curl_formadd(mHandle, LastItem, Option, Value, Option1, Value1, _
		  Option2, Value2, Option3, Value3, Option4, Value4, Option5, Value5, Option6, _
		   Value6, Option7, Value7, Option8, Value8, Option9, Value9, Option10, Value10, CURLFORM_END)
		  
		  Return mLastError = 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function FormGetCallback(UserData As Integer, Buffer As Ptr, Length As Integer) As Integer
		  #pragma X86CallingConvention CDecl
		  
		  If FormGetStreams = Nil Then Return 0
		  Dim ref As Variant = FormGetStreams.Lookup(UserData, Nil)
		  Select Case ref
		  Case IsA Writeable
		    Dim stream As Writeable = ref
		    Dim mb As MemoryBlock = Buffer
		    stream.Write(mb.StringValue(0, Length))
		    Return Length
		    
		  Case IsA MultipartForm
		    Return MultipartForm(ref).curlFormGet(Buffer, Length)
		    
		  Else
		    Break ' UserData does not refer to a valid stream or form!
		    
		  End Select
		  
		  
		Exception Err As RuntimeException
		  If Err IsA ThreadEndException Or Err IsA EndException Then Raise Err
		  Return 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetElement(Index As Integer) As libcURL.MultipartFormElement
		  ' Returns a reference to the MultipartFormElement at the specified index; if the index is out of bounds
		  ' then an OutOfBoundsException will be raised. 
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libcURL/wiki/libcURL.MultipartForm.GetElement
		  
		  
		  Dim e As libcURL.MultipartFormElement = Me.FirstItem
		  Dim i As Integer
		  Do
		    If i < Index Then
		      e = e.NextElement
		      If e = Nil Then
		        Dim err As New OutOfBoundsException
		        err.Message = "The form does not contain an element at that index."
		        Raise err
		      End If
		      
		    ElseIf i = Index Then
		      Return e
		      
		    Else
		      Dim err As New OutOfBoundsException
		      err.Message = "Form indices must be greater than or equal to zero."
		      Raise err
		    End If
		    i = i + 1
		    
		  Loop
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetElement(Name As String) As Integer
		  ' Returns a reference to the first MultipartFormElement that matches the given name.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libcURL/wiki/libcURL.MultipartForm.GetElement
		  
		  Dim e As libcURL.MultipartFormElement = Me.FirstItem
		  Dim i As Integer
		  Do Until e = Nil
		    If e.Name = Name Then Return i
		    e = e.NextElement()
		    i = i + 1
		  Loop
		  Return -1
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function GetStream(UserData As Ptr) As Readable
		  For Each h As EasyHandle In mStreams
		    If h.Handle = Integer(UserData) Then Return h.UploadStream
		  Next
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Shared Function MimeType(File As FolderItem) As String
		  Select Case NthField(File.Name, ".", CountFields(File.Name, "."))
		  Case "ez"
		    Return "application/andrew-inset"
		  Case "aw"
		    Return "application/applixware"
		  Case "atom"
		    Return "application/atom+xml"
		  Case "atomcat"
		    Return "application/atomcat+xml"
		  Case "atomsvc"
		    Return "application/atomsvc+xml"
		  Case "ccxml"
		    Return "application/ccxml+xml"
		  Case "cdmia"
		    Return "application/cdmi-capability"
		  Case "cdmic"
		    Return "application/cdmi-container"
		  Case "cdmid"
		    Return "application/cdmi-domain"
		  Case "cdmio"
		    Return "application/cdmi-object"
		  Case "cdmiq"
		    Return "application/cdmi-queue"
		  Case "cu"
		    Return "application/cu-seeme"
		  Case "davmount"
		    Return "application/davmount+xml"
		  Case "daa"
		    Return "application/x-daa"
		  Case "dssc"
		    Return "application/dssc+der"
		  Case "xdssc"
		    Return "application/dssc+xml"
		  Case "ecma"
		    Return "application/ecmascript"
		  Case "emma"
		    Return "application/emma+xml"
		  Case "epub"
		    Return "application/epub+zip"
		  Case "exi"
		    Return "application/exi"
		  Case "pfr"
		    Return "application/font-tdpfr"
		  Case "stk"
		    Return "application/hyperstudio"
		  Case "ipfix"
		    Return "application/ipfix"
		  Case "jar"
		    Return "application/java-archive"
		  Case "ser"
		    Return "application/java-serialized-object"
		  Case "class"
		    Return "application/java-vm"
		  Case "js"
		    Return "application/javascript"
		  Case "json"
		    Return "application/json"
		  Case "lostxml"
		    Return "application/lost+xml"
		  Case "hqx"
		    Return "application/mac-binhex40"
		  Case "cpt"
		    Return "application/mac-compactpro"
		  Case "mads"
		    Return "application/mads+xml"
		  Case "mrc"
		    Return "application/marc"
		  Case "mrcx"
		    Return "application/marcxml+xml"
		  Case "ma", "nb", "mb"
		    Return "application/mathematica"
		  Case "mathml"
		    Return "application/mathml+xml"
		  Case "mbox"
		    Return "application/mbox"
		  Case "mscml"
		    Return "application/mediaservercontrol+xml"
		  Case "meta4"
		    Return "application/metalink4+xml"
		  Case "mets"
		    Return "application/mets+xml"
		  Case "mods"
		    Return "application/mods+xml"
		  Case "m21"
		    Return "application/mp21"
		  Case "mp21"
		    Return "application/mp21"
		  Case "mp4s"
		    Return "application/mp4"
		  Case "doc"
		    Return "application/msword"
		  Case "dot"
		    Return "application/msword"
		  Case "mxf"
		    Return "application/mxf"
		  Case "asc", "sig"
		    Return "application/pgp-signature"
		  Case "prf"
		    Return "application/pics-rules"
		  Case "p10"
		    Return "application/pkcs10"
		  Case "p7m"
		    Return "application/pkcs7-mime"
		  Case "p7c"
		    Return "application/pkcs7-mime"
		  Case "p7s"
		    Return "application/pkcs7-signature"
		  Case "p8"
		    Return "application/pkcs8"
		  Case "ac"
		    Return "application/pkix-attr-cert"
		  Case "cer"
		    Return "application/pkix-cert"
		  Case "crl"
		    Return "application/pkix-crl"
		  Case "pkipath"
		    Return "application/pkix-pkipath"
		  Case "pki"
		    Return "application/pkixcmp"
		  Case "pls"
		    Return "application/pls+xml"
		  Case "ai", "eps", "ps"
		    Return "application/postscript"
		  Case "cww"
		    Return "application/prs.cww"
		  Case "pskcxml"
		    Return "application/pskc+xml"
		  Case "rdf"
		    Return "application/rdf+xml"
		  Case "rif"
		    Return "application/reginfo+xml"
		  Case "rnc"
		    Return "application/relax-ng-compact-syntax"
		  Case "rl"
		    Return "application/resource-lists+xml"
		  Case "rld"
		    Return "application/resource-lists-diff+xml"
		  Case "rs"
		    Return "application/rls-services+xml"
		  Case "rsd"
		    Return "application/rsd+xml"
		  Case "rss"
		    Return "application/rss+xml"
		  Case "rtf"
		    Return "application/rtf"
		  Case "sbml"
		    Return "application/sbml+xml"
		  Case "scq"
		    Return "application/scvp-cv-request"
		  Case "scs"
		    Return "application/scvp-cv-response"
		  Case "spq"
		    Return "application/scvp-vp-request"
		  Case "spp"
		    Return "application/scvp-vp-response"
		  Case "sdp"
		    Return "application/sdp"
		  Case "setpay"
		    Return "application/set-payment-initiation"
		  Case "setreg"
		    Return "application/set-registration-initiation"
		  Case "shf"
		    Return "application/shf+xml"
		  Case "smi", "smil"
		    Return "application/smil+xml"
		  Case "rq"
		    Return "application/sparql-query"
		  Case "srx"
		    Return "application/sparql-results+xml"
		  Case "gram"
		    Return "application/srgs"
		  Case "grxml"
		    Return "application/srgs+xml"
		  Case "sru"
		    Return "application/sru+xml"
		  Case "ssml"
		    Return "application/ssml+xml"
		  Case "tei"
		    Return "application/tei+xml"
		  Case "teicorpus"
		    Return "application/tei+xml"
		  Case "tfi"
		    Return "application/thraud+xml"
		  Case "tsd"
		    Return "application/timestamped-data"
		  Case "plb"
		    Return "application/vnd.3gpp.pic-bw-large"
		  Case "psb"
		    Return "application/vnd.3gpp.pic-bw-small"
		  Case "pvb"
		    Return "application/vnd.3gpp.pic-bw-var"
		  Case "tcap"
		    Return "application/vnd.3gpp2.tcap"
		  Case "pwn"
		    Return "application/vnd.3m.post-it-notes"
		  Case "aso"
		    Return "application/vnd.accpac.simply.aso"
		  Case "imp"
		    Return "application/vnd.accpac.simply.imp"
		  Case "acu"
		    Return "application/vnd.acucobol"
		  Case "atc"
		    Return "application/vnd.acucorp"
		  Case "acutc"
		    Return "application/vnd.acucorp"
		  Case "air"
		    Return "application/vnd.adobe.air-application-installer-package+zip"
		  Case "fxp"
		    Return "application/vnd.adobe.fxp"
		  Case "fxpl"
		    Return "application/vnd.adobe.fxp"
		  Case "xdp"
		    Return "application/vnd.adobe.xdp+xml"
		  Case "xfdf"
		    Return "application/vnd.adobe.xfdf"
		  Case "ahead"
		    Return "application/vnd.ahead.space"
		  Case "azf"
		    Return "application/vnd.airzip.filesecure.azf"
		  Case "azs"
		    Return "application/vnd.airzip.filesecure.azs"
		  Case "azw"
		    Return "application/vnd.amazon.ebook"
		  Case "acc"
		    Return "application/vnd.americandynamics.acc"
		  Case "ami"
		    Return "application/vnd.amiga.ami"
		  Case "apk"
		    Return "application/vnd.android.package-archive"
		  Case "cii"
		    Return "application/vnd.anser-web-certificate-issue-initiation"
		  Case "fti"
		    Return "application/vnd.anser-web-funds-transfer-initiation"
		  Case "atx"
		    Return "application/vnd.antix.game-component"
		  Case "mpkg"
		    Return "application/vnd.apple.installer+xml"
		  Case "m3u8"
		    Return "application/vnd.apple.mpegurl"
		  Case "swi"
		    Return "application/vnd.aristanetworks.swi"
		  Case "aep"
		    Return "application/vnd.audiograph"
		  Case "mpm"
		    Return "application/vnd.blueice.multipass"
		  Case "bmi"
		    Return "application/vnd.bmi"
		  Case "rep"
		    Return "application/vnd.businessobjects"
		  Case "cdxml"
		    Return "application/vnd.chemdraw+xml"
		  Case "mmd"
		    Return "application/vnd.chipnuts.karaoke-mmd"
		  Case "cdy"
		    Return "application/vnd.cinderella"
		  Case "cla"
		    Return "application/vnd.claymore"
		  Case "rp9"
		    Return "application/vnd.cloanto.rp9"
		  Case "c4g", "c4d", "c4f", "c4p", "c4u"
		    Return "application/vnd.clonk.c4group"
		  Case "c11amc"
		    Return "application/vnd.cluetrust.cartomobile-config"
		  Case "c11amz"
		    Return "application/vnd.cluetrust.cartomobile-config-pkg"
		  Case "csp"
		    Return "application/vnd.commonspace"
		  Case "cdbcmsg"
		    Return "application/vnd.contact.cmsg"
		  Case "cmc"
		    Return "application/vnd.cosmocaller"
		  Case "clkx"
		    Return "application/vnd.crick.clicker"
		  Case "clkk"
		    Return "application/vnd.crick.clicker.keyboard"
		  Case "clkp"
		    Return "application/vnd.crick.clicker.palette"
		  Case "clkt"
		    Return "application/vnd.crick.clicker.template"
		  Case "clkw"
		    Return "application/vnd.crick.clicker.wordbank"
		  Case "wbs"
		    Return "application/vnd.criticaltools.wbs+xml"
		  Case "pml"
		    Return "application/vnd.ctc-posml"
		  Case "ppd"
		    Return "application/vnd.cups-ppd"
		  Case "car"
		    Return "application/vnd.curl.car"
		  Case "pcurl"
		    Return "application/vnd.curl.pcurl"
		  Case "rdz"
		    Return "application/vnd.data-vision.rdz"
		  Case "uvf", "uvvf", "uvd", "uvvd"
		    Return "application/vnd.dece.data"
		  Case "uvt", "uvvt"
		    Return "application/vnd.dece.ttml+xml"
		  Case "uvx"
		    Return "application/vnd.dece.unspecified"
		  Case "uvvx"
		    Return "application/vnd.dece.unspecified"
		  Case "fe_launch"
		    Return "application/vnd.denovo.fcselayout-link"
		  Case "dna"
		    Return "application/vnd.dna"
		  Case "mlp"
		    Return "application/vnd.dolby.mlp"
		  Case "dpg"
		    Return "application/vnd.dpgraph"
		  Case "dfac"
		    Return "application/vnd.dreamfactory"
		  Case "ait"
		    Return "application/vnd.dvb.ait"
		  Case "svc"
		    Return "application/vnd.dvb.service"
		  Case "geo"
		    Return "application/vnd.dynageo"
		  Case "mag"
		    Return "application/vnd.ecowin.chart"
		  Case "nml"
		    Return "application/vnd.enliven"
		  Case "esf"
		    Return "application/vnd.epson.esf"
		  Case "msf"
		    Return "application/vnd.epson.msf"
		  Case "qam"
		    Return "application/vnd.epson.quickanime"
		  Case "slt"
		    Return "application/vnd.epson.salt"
		  Case "ssf"
		    Return "application/vnd.epson.ssf"
		  Case "es3"
		    Return "application/vnd.eszigno3+xml"
		  Case "et3"
		    Return "application/vnd.eszigno3+xml"
		  Case "ez2"
		    Return "application/vnd.ezpix-album"
		  Case "ez3"
		    Return "application/vnd.ezpix-package"
		  Case "fdf"
		    Return "application/vnd.fdf"
		  Case "mseed"
		    Return "application/vnd.fdsn.mseed"
		  Case "seed", "dataless"
		    Return "application/vnd.fdsn.seed"
		  Case "gph"
		    Return "application/vnd.flographit"
		  Case "ftc"
		    Return "application/vnd.fluxtime.clip"
		  Case "fm", "frame", "maker", "book"
		    Return "application/vnd.framemaker"
		  Case "fnc"
		    Return "application/vnd.frogans.fnc"
		  Case "ltf"
		    Return "application/vnd.frogans.ltf"
		  Case "fsc"
		    Return "application/vnd.fsc.weblaunch"
		  Case "oas"
		    Return "application/vnd.fujitsu.oasys"
		  Case "oa2"
		    Return "application/vnd.fujitsu.oasys2"
		  Case "oa3"
		    Return "application/vnd.fujitsu.oasys3"
		  Case "fg5"
		    Return "application/vnd.fujitsu.oasysgp"
		  Case "bh2"
		    Return "application/vnd.fujitsu.oasysprs"
		  Case "ddd"
		    Return "application/vnd.fujixerox.ddd"
		  Case "xdw"
		    Return "application/vnd.fujixerox.docuworks"
		  Case "xbd"
		    Return "application/vnd.fujixerox.docuworks.binder"
		  Case "fzs"
		    Return "application/vnd.fuzzysheet"
		  Case "txd"
		    Return "application/vnd.genomatix.tuxedo"
		  Case "ggb"
		    Return "application/vnd.geogebra.file"
		  Case "ggt"
		    Return "application/vnd.geogebra.tool"
		  Case "gex", "gre"
		    Return "application/vnd.geometry-explorer"
		  Case "gxt"
		    Return "application/vnd.geonext"
		  Case "g2w"
		    Return "application/vnd.geoplan"
		  Case "g3w"
		    Return "application/vnd.geospace"
		  Case "gmx"
		    Return "application/vnd.gmx"
		  Case "kml"
		    Return "application/vnd.google-earth.kml+xml"
		  Case "kmz"
		    Return "application/vnd.google-earth.kmz"
		  Case "gqf", "gqs"
		    Return "application/vnd.grafeq"
		  Case "gac"
		    Return "application/vnd.groove-account"
		  Case "ghf"
		    Return "application/vnd.groove-help"
		  Case "gim"
		    Return "application/vnd.groove-identity-message"
		  Case "grv"
		    Return "application/vnd.groove-injector"
		  Case "gtm"
		    Return "application/vnd.groove-tool-message"
		  Case "tpl"
		    Return "application/vnd.groove-tool-template"
		  Case "vcg"
		    Return "application/vnd.groove-vcard"
		  Case "hal"
		    Return "application/vnd.hal+xml"
		  Case "zmm"
		    Return "application/vnd.handheld-entertainment+xml"
		  Case "hbci"
		    Return "application/vnd.hbci"
		  Case "les"
		    Return "application/vnd.hhe.lesson-player"
		  Case "hpgl"
		    Return "application/vnd.hp-hpgl"
		  Case "hpid"
		    Return "application/vnd.hp-hpid"
		  Case "hps"
		    Return "application/vnd.hp-hps"
		  Case "jlt"
		    Return "application/vnd.hp-jlyt"
		  Case "pcl"
		    Return "application/vnd.hp-pcl"
		  Case "pclxl"
		    Return "application/vnd.hp-pclxl"
		  Case "sfd-hdstx"
		    Return "application/vnd.hydrostatix.sof-data"
		  Case "x3d"
		    Return "application/vnd.hzn-3d-crossword"
		  Case "mpy"
		    Return "application/vnd.ibm.minipay"
		  Case "afp", "listafp", "list3820"
		    Return "application/vnd.ibm.modcap"
		  Case "irm"
		    Return "application/vnd.ibm.rights-management"
		  Case "sc"
		    Return "application/vnd.ibm.secure-container"
		  Case "icc", "icm"
		    Return "application/vnd.iccprofile"
		  Case "igl"
		    Return "application/vnd.igloader"
		  Case "ivp"
		    Return "application/vnd.immervision-ivp"
		  Case "ivu"
		    Return "application/vnd.immervision-ivu"
		  Case "igm"
		    Return "application/vnd.insors.igm"
		  Case "xpw", "xpx"
		    Return "application/vnd.intercon.formnet"
		  Case "i2g"
		    Return "application/vnd.intergeo"
		  Case "qbo"
		    Return "application/vnd.intu.qbo"
		  Case "qfx"
		    Return "application/vnd.intu.qfx"
		  Case "rcprofile"
		    Return "application/vnd.ipunplugged.rcprofile"
		  Case "irp"
		    Return "application/vnd.irepository.package+xml"
		  Case "xpr"
		    Return "application/vnd.is-xpr"
		  Case "fcs"
		    Return "application/vnd.isac.fcs"
		  Case "jam"
		    Return "application/vnd.jam"
		  Case "rms"
		    Return "application/vnd.jcp.javame.midlet-rms"
		  Case "jisp"
		    Return "application/vnd.jisp"
		  Case "joda"
		    Return "application/vnd.joost.joda-archive"
		  Case "ktz"
		    Return "application/vnd.kahootz"
		  Case "ktr"
		    Return "application/vnd.kahootz"
		  Case "karbon"
		    Return "application/vnd.kde.karbon"
		  Case "chrt"
		    Return "application/vnd.kde.kchart"
		  Case "kfo"
		    Return "application/vnd.kde.kformula"
		  Case "flw"
		    Return "application/vnd.kde.kivio"
		  Case "kon"
		    Return "application/vnd.kde.kontour"
		  Case "kpr"
		    Return "application/vnd.kde.kpresenter"
		  Case "ksp"
		    Return "application/vnd.kde.kspread"
		  Case "kwd"
		    Return "application/vnd.kde.kword"
		  Case "htke"
		    Return "application/vnd.kenameaapp"
		  Case "kia"
		    Return "application/vnd.kidspiration"
		  Case "kne"
		    Return "application/vnd.kinar"
		  Case "skp"
		    Return "application/vnd.koan"
		  Case "sse"
		    Return "application/vnd.kodak-descriptor"
		  Case "lasxml"
		    Return "application/vnd.las.las+xml"
		  Case "lbd"
		    Return "application/vnd.llamagraphics.life-balance.desktop"
		  Case "lbe"
		    Return "application/vnd.llamagraphics.life-balance.exchange+xml"
		  Case "123"
		    Return "application/vnd.lotus-1-2-3"
		  Case "apr"
		    Return "application/vnd.lotus-approach"
		  Case "pre"
		    Return "application/vnd.lotus-freelance"
		  Case "nsf"
		    Return "application/vnd.lotus-notes"
		  Case "org"
		    Return "application/vnd.lotus-organizer"
		  Case "scm"
		    Return "application/vnd.lotus-screencam"
		  Case "lwp"
		    Return "application/vnd.lotus-wordpro"
		  Case "portpkg"
		    Return "application/vnd.macports.portpkg"
		  Case "mcd"
		    Return "application/vnd.mcd"
		  Case "mc1"
		    Return "application/vnd.medcalcdata"
		  Case "cdkey"
		    Return "application/vnd.mediastation.cdkey"
		  Case "mwf"
		    Return "application/vnd.mfer"
		  Case "mfm"
		    Return "application/vnd.mfmp"
		  Case "flo"
		    Return "application/vnd.micrografx.flo"
		  Case "igx"
		    Return "application/vnd.micrografx.igx"
		  Case "mif"
		    Return "application/vnd.mif"
		  Case "daf"
		    Return "application/vnd.mobius.daf"
		  Case "dis"
		    Return "application/vnd.mobius.dis"
		  Case "mbk"
		    Return "application/vnd.mobius.mbk"
		  Case "mqy"
		    Return "application/vnd.mobius.mqy"
		  Case "msl"
		    Return "application/vnd.mobius.msl"
		  Case "plc"
		    Return "application/vnd.mobius.plc"
		  Case "txf"
		    Return "application/vnd.mobius.txf"
		  Case "mpn"
		    Return "application/vnd.mophun.application"
		  Case "mpc"
		    Return "application/vnd.mophun.certificate"
		  Case "xul"
		    Return "application/vnd.mozilla.xul+xml"
		  Case "cil"
		    Return "application/vnd.ms-artgalry"
		  Case "cab"
		    Return "application/vnd.ms-cab-compressed"
		  Case "xls", "xlm", "xla", "xlc", "xlt", "xlw"
		    Return "application/vnd.ms-excel"
		  Case "xlam"
		    Return "application/vnd.ms-excel.addin.macroenabled.12"
		  Case "xlsb"
		    Return "application/vnd.ms-excel.sheet.binary.macroenabled.12"
		  Case "xlsm"
		    Return "application/vnd.ms-excel.sheet.macroenabled.12"
		  Case "xltm"
		    Return "application/vnd.ms-excel.template.macroenabled.12"
		  Case "eot"
		    Return "application/vnd.ms-fontobject"
		  Case "chm"
		    Return "application/vnd.ms-htmlhelp"
		  Case "ims"
		    Return "application/vnd.ms-ims"
		  Case "lrm"
		    Return "application/vnd.ms-lrm"
		  Case "thmx"
		    Return "application/vnd.ms-officetheme"
		  Case "cat"
		    Return "application/vnd.ms-pki.seccat"
		  Case "stl"
		    Return "application/vnd.ms-pki.stl"
		  Case "ppt"
		    Return "application/vnd.ms-powerpoint"
		  Case "pps"
		    Return "application/vnd.ms-powerpoint"
		  Case "ppam"
		    Return "application/vnd.ms-powerpoint.addin.macroenabled.12"
		  Case "pptm"
		    Return "application/vnd.ms-powerpoint.presentation.macroenabled.12"
		  Case "sldm"
		    Return "application/vnd.ms-powerpoint.slide.macroenabled.12"
		  Case "ppsm"
		    Return "application/vnd.ms-powerpoint.slideshow.macroenabled.12"
		  Case "potm"
		    Return "application/vnd.ms-powerpoint.template.macroenabled.12"
		  Case "mpp", "mpt"
		    Return "application/vnd.ms-project"
		  Case "docm"
		    Return "application/vnd.ms-word.document.macroenabled.12"
		  Case "dotm"
		    Return "application/vnd.ms-word.template.macroenabled.12"
		  Case "wps", "wks", "wcm", "wdb"
		    Return "application/vnd.ms-works"
		  Case "wpl"
		    Return "application/vnd.ms-wpl"
		  Case "xps"
		    Return "application/vnd.ms-xpsdocument"
		  Case "mseq"
		    Return "application/vnd.mseq"
		  Case "mus"
		    Return "application/vnd.musician"
		  Case "msty"
		    Return "application/vnd.muvee.style"
		  Case "nlu"
		    Return "application/vnd.neurolanguage.nlu"
		  Case "nnd"
		    Return "application/vnd.noblenet-directory"
		  Case "nns"
		    Return "application/vnd.noblenet-sealer"
		  Case "nnw"
		    Return "application/vnd.noblenet-web"
		  Case "ngdat"
		    Return "application/vnd.nokia.n-gage.data"
		  Case "n-gage"
		    Return "application/vnd.nokia.n-gage.symbian.install"
		  Case "rpst"
		    Return "application/vnd.nokia.radio-preset"
		  Case "rpss"
		    Return "application/vnd.nokia.radio-presets"
		  Case "edm"
		    Return "application/vnd.novadigm.edm"
		  Case "edx"
		    Return "application/vnd.novadigm.edx"
		  Case "ext"
		    Return "application/vnd.novadigm.ext"
		  Case "odc"
		    Return "application/vnd.oasis.opendocument.chart"
		  Case "otc"
		    Return "application/vnd.oasis.opendocument.chart-template"
		  Case "odb"
		    Return "application/vnd.oasis.opendocument.database"
		  Case "odf"
		    Return "application/vnd.oasis.opendocument.formula"
		  Case "odft"
		    Return "application/vnd.oasis.opendocument.formula-template"
		  Case "odg"
		    Return "application/vnd.oasis.opendocument.graphics"
		  Case "otg"
		    Return "application/vnd.oasis.opendocument.graphics-template"
		  Case "odi"
		    Return "application/vnd.oasis.opendocument.image"
		  Case "oti"
		    Return "application/vnd.oasis.opendocument.image-template"
		  Case "odp"
		    Return "application/vnd.oasis.opendocument.presentation"
		  Case "otp"
		    Return "application/vnd.oasis.opendocument.presentation-template"
		  Case "ods"
		    Return "application/vnd.oasis.opendocument.spreadsheet"
		  Case "ots"
		    Return "application/vnd.oasis.opendocument.spreadsheet-template"
		  Case "odt"
		    Return "application/vnd.oasis.opendocument.text"
		  Case "odm"
		    Return "application/vnd.oasis.opendocument.text-master"
		  Case "ott"
		    Return "application/vnd.oasis.opendocument.text-template"
		  Case "oth"
		    Return "application/vnd.oasis.opendocument.text-web"
		  Case "xo"
		    Return "application/vnd.olpc-sugar"
		  Case "dd2"
		    Return "application/vnd.oma.dd2+xml"
		  Case "oxt"
		    Return "application/vnd.openofficeorg.extension"
		  Case "pptx"
		    Return "application/vnd.openxmlformats-officedocument.presentationml.presentation"
		  Case "sldx"
		    Return "application/vnd.openxmlformats-officedocument.presentationml.slide"
		  Case "ppsx"
		    Return "application/vnd.openxmlformats-officedocument.presentationml.slideshow"
		  Case "potx"
		    Return "application/vnd.openxmlformats-officedocument.presentationml.template"
		  Case "xlsx"
		    Return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
		  Case "xltx"
		    Return "application/vnd.openxmlformats-officedocument.spreadsheetml.template"
		  Case "docx"
		    Return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
		  Case "dotx"
		    Return "application/vnd.openxmlformats-officedocument.wordprocessingml.template"
		  Case "mgp"
		    Return "application/vnd.osgeo.mapguide.package"
		  Case "dp"
		    Return "application/vnd.osgi.dp"
		  Case "pdb"
		    Return "application/vnd.palm"
		  Case "paw"
		    Return "application/vnd.pawaafile"
		  Case "str"
		    Return "application/vnd.pg.format"
		  Case "ei6"
		    Return "application/vnd.pg.osasli"
		  Case "efif"
		    Return "application/vnd.picsel"
		  Case "wg"
		    Return "application/vnd.pmi.widget"
		  Case "plf"
		    Return "application/vnd.pocketlearn"
		  Case "pbd"
		    Return "application/vnd.powerbuilder6"
		  Case "box"
		    Return "application/vnd.previewsystems.box"
		  Case "mgz"
		    Return "application/vnd.proteus.magazine"
		  Case "qps"
		    Return "application/vnd.publishare-delta-tree"
		  Case "ptid"
		    Return "application/vnd.pvi.ptid1"
		  Case "qxd"
		    Return "application/vnd.quark.quarkxpress"
		  Case "bed"
		    Return "application/vnd.realvnc.bed"
		  Case "mxl"
		    Return "application/vnd.recordare.musicxml"
		  Case "musicxml"
		    Return "application/vnd.recordare.musicxml+xml"
		  Case "cryptonote"
		    Return "application/vnd.rig.cryptonote"
		  Case "cod"
		    Return "application/vnd.rim.cod"
		  Case "rm"
		    Return "application/vnd.rn-realmedia"
		  Case "link66"
		    Return "application/vnd.route66.link66+xml"
		  Case "st"
		    Return "application/vnd.sailingtracker.track"
		  Case "see"
		    Return "application/vnd.seemail"
		  Case "sema"
		    Return "application/vnd.sema"
		  Case "semd"
		    Return "application/vnd.semd"
		  Case "semf"
		    Return "application/vnd.semf"
		  Case "ifm"
		    Return "application/vnd.shana.informed.formdata"
		  Case "itp"
		    Return "application/vnd.shana.informed.formtemplate"
		  Case "iif"
		    Return "application/vnd.shana.informed.interchange"
		  Case "ipk"
		    Return "application/vnd.shana.informed.package"
		  Case "twd"
		    Return "application/vnd.simtech-mindmapper"
		  Case "mmf"
		    Return "application/vnd.smaf"
		  Case "teacher"
		    Return "application/vnd.smart.teacher"
		  Case "sdkm"
		    Return "application/vnd.solent.sdkm+xml"
		  Case "dxp"
		    Return "application/vnd.spotfire.dxp"
		  Case "sfs"
		    Return "application/vnd.spotfire.sfs"
		  Case "sdc"
		    Return "application/vnd.stardivision.calc"
		  Case "sda"
		    Return "application/vnd.stardivision.draw"
		  Case "sdd"
		    Return "application/vnd.stardivision.impress"
		  Case "smf"
		    Return "application/vnd.stardivision.math"
		  Case "sdw"
		    Return "application/vnd.stardivision.writer"
		  Case "sgl"
		    Return "application/vnd.stardivision.writer-global"
		  Case "sm"
		    Return "application/vnd.stepmania.stepchart"
		  Case "sxc"
		    Return "application/vnd.sun.xml.calc"
		  Case "stc"
		    Return "application/vnd.sun.xml.calc.template"
		  Case "sxd"
		    Return "application/vnd.sun.xml.draw"
		  Case "std"
		    Return "application/vnd.sun.xml.draw.template"
		  Case "sxi"
		    Return "application/vnd.sun.xml.impress"
		  Case "sti"
		    Return "application/vnd.sun.xml.impress.template"
		  Case "sxm"
		    Return "application/vnd.sun.xml.math"
		  Case "sxw"
		    Return "application/vnd.sun.xml.writer"
		  Case "sxg"
		    Return "application/vnd.sun.xml.writer.global"
		  Case "stw"
		    Return "application/vnd.sun.xml.writer.template"
		  Case "sus"
		    Return "application/vnd.sus-calendar"
		  Case "svd"
		    Return "application/vnd.svd"
		  Case "sis"
		    Return "application/vnd.symbian.install"
		  Case "xsm"
		    Return "application/vnd.syncml+xml"
		  Case "bdm"
		    Return "application/vnd.syncml.dm+wbxml"
		  Case "xdm"
		    Return "application/vnd.syncml.dm+xml"
		  Case "tao"
		    Return "application/vnd.tao.intent-module-archive"
		  Case "tmo"
		    Return "application/vnd.tmobile-livetv"
		  Case "tpt"
		    Return "application/vnd.trid.tpt"
		  Case "mxs"
		    Return "application/vnd.triscape.mxs"
		  Case "tra"
		    Return "application/vnd.trueapp"
		  Case "ufd"
		    Return "application/vnd.ufdl"
		  Case "utz"
		    Return "application/vnd.uiq.theme"
		  Case "umj"
		    Return "application/vnd.umajin"
		  Case "unityweb"
		    Return "application/vnd.unity"
		  Case "uoml"
		    Return "application/vnd.uoml+xml"
		  Case "vcx"
		    Return "application/vnd.vcx"
		  Case "vsd"
		    Return "application/vnd.visio"
		  Case "vis"
		    Return "application/vnd.visionary"
		  Case "vsf"
		    Return "application/vnd.vsf"
		  Case "wbxml"
		    Return "application/vnd.wap.wbxml"
		  Case "wmlc"
		    Return "application/vnd.wap.wmlc"
		  Case "wmlsc"
		    Return "application/vnd.wap.wmlscriptc"
		  Case "wtb"
		    Return "application/vnd.webturbo"
		  Case "nbp"
		    Return "application/vnd.wolfram.player"
		  Case "wpd"
		    Return "application/vnd.wordperfect"
		  Case "wqd"
		    Return "application/vnd.wqd"
		  Case "stf"
		    Return "application/vnd.wt.stf"
		  Case "xar"
		    Return "application/vnd.xara"
		  Case "xfdl"
		    Return "application/vnd.xfdl"
		  Case "hvd"
		    Return "application/vnd.yamaha.hv-dic"
		  Case "hvs"
		    Return "application/vnd.yamaha.hv-script"
		  Case "hvp"
		    Return "application/vnd.yamaha.hv-voice"
		  Case "osf"
		    Return "application/vnd.yamaha.openscoreformat"
		  Case "osfpvg"
		    Return "application/vnd.yamaha.openscoreformat.osfpvg+xml"
		  Case "saf"
		    Return "application/vnd.yamaha.smaf-audio"
		  Case "spf"
		    Return "application/vnd.yamaha.smaf-phrase"
		  Case "cmp"
		    Return "application/vnd.yellowriver-custom-menu"
		  Case "zir"
		    Return "application/vnd.zul"
		  Case "zaz"
		    Return "application/vnd.zzazz.deck+xml"
		  Case "vxml"
		    Return "application/voicexml+xml"
		  Case "wgt"
		    Return "application/widget"
		  Case "hlp"
		    Return "application/winhlp"
		  Case "wsdl"
		    Return "application/wsdl+xml"
		  Case "wspolicy"
		    Return "application/wspolicy+xml"
		  Case "7z"
		    Return "application/x-7z-compressed"
		  Case "abw"
		    Return "application/x-abiword"
		  Case "ace"
		    Return "application/x-ace-compressed"
		  Case "aab"
		    Return "application/x-authorware-bin"
		  Case "aam"
		    Return "application/x-authorware-map"
		  Case "aas"
		    Return "application/x-authorware-seg"
		  Case "bcpio"
		    Return "application/x-bcpio"
		  Case "torrent"
		    Return "application/x-bittorrent"
		  Case "bz"
		    Return "application/x-bzip"
		  Case "bz2"
		    Return "application/x-bzip2"
		  Case "vcd"
		    Return "application/x-cdlink"
		  Case "chat"
		    Return "application/x-chat"
		  Case "pgn"
		    Return "application/x-chess-pgn"
		  Case "cpio"
		    Return "application/x-cpio"
		  Case "csh"
		    Return "application/x-csh"
		  Case "deb"
		    Return "application/x-debian-package"
		  Case "dir"
		    Return "application/x-director"
		  Case "wad"
		    Return "application/x-doom"
		  Case "ncx"
		    Return "application/x-dtbncx+xml"
		  Case "dtb"
		    Return "application/x-dtbook+xml"
		  Case "res"
		    Return "application/x-dtbresource+xml"
		  Case "dvi"
		    Return "application/x-dvi"
		  Case "bdf"
		    Return "application/x-font-bdf"
		  Case "gsf"
		    Return "application/x-font-ghostscript"
		  Case "psf"
		    Return "application/x-font-linux-psf"
		  Case "otf"
		    Return "application/x-font-otf"
		  Case "pcf"
		    Return "application/x-font-pcf"
		  Case "snf"
		    Return "application/x-font-snf"
		  Case "ttf"
		    Return "application/x-font-ttf"
		  Case "pfa"
		    Return "application/x-font-type1"
		  Case "woff"
		    Return "application/x-font-woff"
		  Case "spl"
		    Return "application/x-futuresplash"
		  Case "gnumeric"
		    Return "application/x-gnumeric"
		  Case "gtar"
		    Return "application/x-gtar"
		  Case "hdf"
		    Return "application/x-hdf"
		  Case "jnlp"
		    Return "application/x-java-jnlp-file"
		  Case "latex"
		    Return "application/x-latex"
		  Case "prc"
		    Return "application/x-mobipocket-ebook"
		  Case "mobi"
		    Return "application/x-mobipocket-ebook"
		  Case "m3u8"
		    Return "application/x-mpegurl"
		  Case "application"
		    Return "application/x-ms-application"
		  Case "wmd"
		    Return "application/x-ms-wmd"
		  Case "wmz"
		    Return "application/x-ms-wmz"
		  Case "xbap"
		    Return "application/x-ms-xbap"
		  Case "mdb"
		    Return "application/x-msaccess"
		  Case "obd"
		    Return "application/x-msbinder"
		  Case "crd"
		    Return "application/x-mscardfile"
		  Case "clp"
		    Return "application/x-msclip"
		  Case "exe", "dll", "com", "bat", "msi"
		    Return "application/x-msdownload"
		  Case "mvb"
		    Return "application/x-msmediaview"
		  Case "wmf"
		    Return "application/x-msmetafile"
		  Case "mny"
		    Return "application/x-msmoney"
		  Case "pub"
		    Return "application/x-mspublisher"
		  Case "scd"
		    Return "application/x-msschedule"
		  Case "trm"
		    Return "application/x-msterminal"
		  Case "wri"
		    Return "application/x-mswrite"
		  Case "nc"
		    Return "application/x-netcdf"
		  Case "p12"
		    Return "application/x-pkcs12"
		  Case "p7b"
		    Return "application/x-pkcs7-certificates"
		  Case "p7r"
		    Return "application/x-pkcs7-certreqresp"
		  Case "rar"
		    Return "application/x-rar-compressed"
		  Case "sh"
		    Return "application/x-sh"
		  Case "shar"
		    Return "application/x-shar"
		  Case "swf"
		    Return "application/x-shockwave-flash"
		  Case "xap"
		    Return "application/x-silverlight-app"
		  Case "sit"
		    Return "application/x-stuffit"
		  Case "sitx"
		    Return "application/x-stuffitx"
		  Case "sv4cpio"
		    Return "application/x-sv4cpio"
		  Case "sv4crc"
		    Return "application/x-sv4crc"
		  Case "tar"
		    Return "application/x-tar"
		  Case "tcl"
		    Return "application/x-tcl"
		  Case "tex"
		    Return "application/x-tex"
		  Case "tfm"
		    Return "application/x-tex-tfm"
		  Case "texi"
		    Return "application/x-texinfo"
		  Case "texinfo"
		    Return "application/x-texinfo"
		  Case "ustar"
		    Return "application/x-ustar"
		  Case "src"
		    Return "application/x-wais-source"
		  Case "crt"
		    Return "application/x-x509-ca-cert"
		  Case "der"
		    Return "application/x-x509-ca-cert"
		  Case "fig"
		    Return "application/x-xfig"
		  Case "xpi"
		    Return "application/x-xpinstall"
		  Case "xdf"
		    Return "application/xcap-diff+xml"
		  Case "xenc"
		    Return "application/xenc+xml"
		  Case "xht"
		    Return "application/xhtml+xml"
		  Case "xhtml"
		    Return "application/xhtml+xml"
		  Case "xsl"
		    Return "application/xml"
		  Case "xml"
		    Return "application/xml"
		  Case "dtd"
		    Return "application/xml-dtd"
		  Case "xop"
		    Return "application/xop+xml"
		  Case "xslt"
		    Return "application/xslt+xml"
		  Case "xspf"
		    Return "application/xspf+xml"
		  Case "mxml"
		    Return "application/xv+xml"
		  Case "yang"
		    Return "application/yang"
		  Case "yin"
		    Return "application/yin+xml"
		  Case "zip"
		    Return "application/zip"
		  Case "adp"
		    Return "audio/adpcm"
		  Case "snd"
		    Return "audio/basic"
		  Case "au"
		    Return "audio/basic"
		  Case "midi"
		    Return "audio/midi"
		  Case "mid"
		    Return "audio/midi"
		  Case "mp4a"
		    Return "audio/mp4"
		  Case "m4p"
		    Return "audio/mp4a-latm"
		  Case "m4a"
		    Return "audio/mp4a-latm"
		  Case "mpga", "mp2", "mp2a", "mp3", "m2a", "m3a"
		    Return "audio/mpeg"
		  Case "oga", "ogg", "spx"
		    Return "audio/ogg"
		  Case "weba"
		    Return "audio/webm"
		  Case "aac"
		    Return "audio/x-aac"
		  Case "aif", "aiff", "aifc"
		    Return "audio/x-aiff"
		  Case "m3u"
		    Return "audio/x-mpegurl"
		  Case "wax"
		    Return "audio/x-ms-wax"
		  Case "wma"
		    Return "audio/x-ms-wma"
		  Case "ram", "ra"
		    Return "audio/x-pn-realaudio"
		  Case "rmp"
		    Return "audio/x-pn-realaudio-plugin"
		  Case "wav"
		    Return "audio/x-wav"
		  Case "cdx"
		    Return "chemical/x-cdx"
		  Case "cif"
		    Return "chemical/x-cif"
		  Case "cmdf"
		    Return "chemical/x-cmdf"
		  Case "cml"
		    Return "chemical/x-cml"
		  Case "csml"
		    Return "chemical/x-csml"
		  Case "xyz"
		    Return "chemical/x-xyz"
		  Case "bmp"
		    Return "image/bmp"
		  Case "cgm"
		    Return "image/cgm"
		  Case "g3"
		    Return "image/g3fax"
		  Case "gif"
		    Return "image/gif"
		  Case "ief"
		    Return "image/ief"
		  Case "jp2"
		    Return "image/jp2"
		  Case "jpeg", "jpg", "jpe"
		    Return "image/jpeg"
		  Case "ktx"
		    Return "image/ktx"
		  Case "pict", "pic", "pct"
		    Return "image/pict"
		  Case "png"
		    Return "image/png"
		  Case "btif"
		    Return "image/prs.btif"
		  Case "svg"
		    Return "image/svg+xml"
		  Case "tiff"
		    Return "image/tiff"
		  Case "psd"
		    Return "image/vnd.adobe.photoshop"
		  Case "uvi"
		    Return "image/vnd.dece.graphic"
		  Case "sub"
		    Return "image/vnd.dvb.subtitle"
		  Case "djvu"
		    Return "image/vnd.djvu"
		  Case "dwg"
		    Return "image/vnd.dwg"
		  Case "dxf"
		    Return "image/vnd.dxf"
		  Case "fbs"
		    Return "image/vnd.fastbidsheet"
		  Case "fpx"
		    Return "image/vnd.fpx"
		  Case "fst"
		    Return "image/vnd.fst"
		  Case "mmr"
		    Return "image/vnd.fujixerox.edmics-mmr"
		  Case "rlc"
		    Return "image/vnd.fujixerox.edmics-rlc"
		  Case "mdi"
		    Return "image/vnd.ms-modi"
		  Case "npx"
		    Return "image/vnd.net-fpx"
		  Case "wbmp"
		    Return "image/vnd.wap.wbmp"
		  Case "xif"
		    Return "image/vnd.xiff"
		  Case "webp"
		    Return "image/webp"
		  Case "ras"
		    Return "image/x-cmu-raster"
		  Case "cmx"
		    Return "image/x-cmx"
		  Case "fh"
		    Return "image/x-freehand"
		  Case "ico"
		    Return "image/x-icon"
		  Case "pntg", "pnt","mac"
		    Return "image/x-macpaint"
		  Case "pcx"
		    Return "image/x-pcx"
		  Case "pdf"
		    Return "application/pdf"
		  Case "pnm"
		    Return "image/x-portable-anymap"
		  Case "pbm"
		    Return "image/x-portable-bitmap"
		  Case "pgm"
		    Return "image/x-portable-graymap"
		  Case "ppm"
		    Return "image/x-portable-pixmap"
		  Case "qti", "qtif"
		    Return "image/x-quicktime"
		  Case "rgb"
		    Return "image/x-rgb"
		  Case "xbm"
		    Return "image/x-xbitmap"
		  Case "xpm"
		    Return "image/x-xpixmap"
		  Case "xwd"
		    Return "image/x-xwindowdump"
		  Case "mime", "eml"
		    Return "message/rfc822"
		  Case "igs"
		    Return "model/iges"
		  Case "msh"
		    Return "model/mesh"
		  Case "dae"
		    Return "model/vnd.collada+xml"
		  Case "dwf"
		    Return "model/vnd.dwf"
		  Case "gdl"
		    Return "model/vnd.gdl"
		  Case "gtw"
		    Return "model/vnd.gtw"
		  Case "mts"
		    Return "model/vnd.mts"
		  Case "vtu"
		    Return "model/vnd.vtu"
		  Case "vrml"
		    Return "model/vrml"
		  Case "manifest"
		    Return "text/cache-manifest"
		  Case "ics"
		    Return "text/calendar"
		  Case "css"
		    Return "text/css"
		  Case "csv"
		    Return "text/csv"
		  Case "html", "htm"
		    Return "text/html"
		  Case "n3"
		    Return "text/n3"
		  Case "txt", "text", "conf", "def", "list", "log", "in", "md"
		    Return "text/plain"
		  Case "dsc"
		    Return "text/prs.lines.tag"
		  Case "rtx"
		    Return "text/richtext"
		  Case "sgml"
		    Return "text/sgml"
		  Case "tsv"
		    Return "text/tab-separated-values"
		  Case "t", "tr", "roff"
		    Return "text/troff"
		  Case "ttl"
		    Return "text/turtle"
		  Case "uri", "uris", "urls"
		    Return "text/uri-list"
		  Case "curl"
		    Return "text/vnd.curl"
		  Case "dcurl"
		    Return "text/vnd.curl.dcurl"
		  Case "scurl"
		    Return "text/vnd.curl.scurl"
		  Case "mcurl"
		    Return "text/vnd.curl.mcurl"
		  Case "fly"
		    Return "text/vnd.fly"
		  Case "flx"
		    Return "text/vnd.fmi.flexstor"
		  Case "gv"
		    Return "text/vnd.graphviz"
		  Case "3dml"
		    Return "text/vnd.in3d.3dml"
		  Case "spot"
		    Return "text/vnd.in3d.spot"
		  Case "jad"
		    Return "text/vnd.sun.j2me.app-descriptor"
		  Case "wml"
		    Return "text/vnd.wap.wml"
		  Case "wmls"
		    Return "text/vnd.wap.wmlscript"
		  Case "asm"
		    Return "text/x-asm"
		  Case "c", "cc", "cxx", "cpp", "h"
		    Return "text/x-c"
		  Case "pas"
		    Return "text/x-pascal"
		  Case "java"
		    Return "text/x-java-source"
		  Case "etx"
		    Return "text/x-setext"
		  Case "uu"
		    Return "text/x-uuencode"
		  Case "vcs"
		    Return "text/x-vcalendar"
		  Case "vcf"
		    Return "text/x-vcard"
		  Case "3gp"
		    Return "video/3gpp"
		  Case "3g2"
		    Return "video/3gpp2"
		  Case "h261"
		    Return "video/h261"
		  Case "h263"
		    Return "video/h263"
		  Case "h264"
		    Return "video/h264"
		  Case "jpgv"
		    Return "video/jpeg"
		  Case "jpm"
		    Return "video/jpm"
		  Case "mj2"
		    Return "video/mj2"
		  Case "ts"
		    Return "video/mp2t"
		  Case "mp4", "mp4v", "mpg4", "m4v"
		    Return "video/mp4"
		  Case "mpeg", "mpg", "mpe", "m1v", "m2v"
		    Return "video/mpeg"
		  Case "ogv"
		    Return "video/ogg"
		  Case "mov", "qt"
		    Return "video/quicktime"
		  Case "uvh"
		    Return "video/vnd.dece.hd"
		  Case "uvm"
		    Return "video/vnd.dece.mobile"
		  Case "uvp"
		    Return "video/vnd.dece.pd"
		  Case "uvs"
		    Return "video/vnd.dece.sd"
		  Case "uvv"
		    Return "video/vnd.dece.video"
		  Case "fvt"
		    Return "video/vnd.fvt"
		  Case "mxu"
		    Return "video/vnd.mpegurl"
		  Case "pyv"
		    Return "video/vnd.ms-playready.media.pyv"
		  Case "uvu"
		    Return "video/vnd.uvvu.mp4"
		  Case "viv"
		    Return "video/vnd.vivo"
		  Case "dif"
		    Return "video/x-dv"
		  Case "dv"
		    Return "video/x-dv"
		  Case "webm"
		    Return "video/webm"
		  Case "f4v"
		    Return "video/x-f4v"
		  Case "fli"
		    Return "video/x-fli"
		  Case "flv"
		    Return "video/x-flv"
		  Case "m4v"
		    Return "video/x-m4v"
		  Case "rbp", "rbbas", "rbvcp", "rbo"
		    Return "application/x-REALbasic-Project"
		  Case "asx", "asf"
		    Return "video/x-ms-asf"
		  Case "wm"
		    Return "video/x-ms-wm"
		  Case "wmv"
		    Return "video/x-ms-wmv"
		  Case "wmx"
		    Return "video/x-ms-wmx"
		  Case "wvx"
		    Return "video/x-ms-wvx"
		  Case "avi"
		    Return "video/x-msvideo"
		  Case "movie"
		    Return "video/x-sgi-movie"
		  Case "ice"
		    Return "x-conference/x-cooltalk"
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Operator_Compare(OtherForm As libcURL.MultipartForm) As Integer
		  ' Overloads the comparison operator(=), permitting direct comparisons between instances of MultipartForm.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libcURL/wiki/libcURL.MultipartForm.Operator_Compare
		  
		  Dim i As Integer = Super.Operator_Compare(OtherForm)
		  If i = 0 Then i = Sign(mHandle - OtherForm.Handle)
		  Return i
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Operator_Convert() As Dictionary
		  Dim e As MultipartFormElement = Me.FirstItem
		  If e = Nil Then Return Nil
		  Dim d As New Dictionary
		  Do Until e = Nil
		    Select Case e.Type
		    Case libcURL.FormElementType.File
		      d.Value(e.Name) = GetFolderItem(e.Contents)
		    Case libcURL.FormElementType.MemoryBlock
		      d.Value(e.Name) = e.Buffer
		    Case libcURL.FormElementType.String
		      d.Value(e.Name) = e.Contents
		    Case libcURL.FormElementType.Stream
		      d.Value(e.Name) = e.Stream
		    End Select
		    e = e.NextElement
		  Loop
		  Return d
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Operator_Convert(FromDict As Dictionary)
		  ' Overloads the conversion operator(=), permitting implicit and explicit conversion from a Dictionary
		  ' into a MultipartForm. The dictionary contains NAME:VALUE pairs comprising HTML form elements: NAME
		  ' is a string containing the form-element name; VALUE may be a string, FolderItem, or an instance of
		  ' EasyHandle whose DataNeeded event will be raised when the form is actually used.
		  '
		  ' See:
		  ' https://github.com/charonn0/RB-libcURL/wiki/libcURL.MultipartForm.Operator_Convert
		  
		  If mLastError = libcURL.Errors.NOT_INITIALIZED Then
		    Me.Constructor()
		  Else
		    Me.Destructor() ' free the previous form data
		  End If
		  If FromDict = Nil Then Return
		  
		  ' loop over the dictionary
		  For Each item As String In FromDict.Keys
		    Dim value As Variant = FromDict.Value(item)
		    Select Case True
		    Case VarType(value) = Variant.TypeString
		      If Not Me.AddElement(item, value.StringValue) Then Raise New cURLException(Me)
		      
		    Case value IsA FolderItem
		      If Not Me.AddElement(item, FolderItem(value)) Then Raise New cURLException(Me)
		      
		    Case value IsA Readable ' rtfm about CURLFORM_STREAM before using this
		      If Not Me.AddElement(item, Readable(value), 0) Then Raise New cURLException(Me)
		      
		    Case value IsA MemoryBlock
		      Dim mb As MemoryBlock = Value
		      If Not Me.AddElement(item, mb, "") Then Raise New cURLException(Me)
		      
		    Else
		      Raise New UnsupportedFormatException
		    End Select
		  Next
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Serialize() As String
		  ' Serialize the form structure into a multipart/form-data string. The serialized form may be used with
		  ' other HTTP libraries, including the built-in HTTPSocket.
		  '
		  ' See:
		  ' http://curl.haxx.se/libcurl/c/curl_formget.html
		  ' https://github.com/charonn0/RB-libcURL/wiki/libcURL.MultipartForm.Serialize
		  
		  Dim mb As New MemoryBlock(0)
		  Dim formstream As New BinaryStream(mb)
		  If Me.Serialize(formstream) Then
		    formstream.Close
		    Return mb
		  Else
		    If mLastError <> 0 Then Raise New cURLException(Me)
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Serialize(WriteTo As Writeable) As Boolean
		  ' Serialize the form and write the output to WriteTo. The serialized form may be used with
		  ' other HTTP libraries, including the built-in HTTPSocket. If WriteTo is Nil then the
		  ' SerializePart event will be raised in lieu of writing the data to a stream.
		  '
		  ' See:
		  ' http://curl.haxx.se/libcurl/c/curl_formget.html
		  ' https://github.com/charonn0/RB-libcURL/wiki/libcURL.MultipartForm.Serialize
		  
		  If mHandle = 0 Then Return False
		  If Not libcURL.Version.IsAtLeast(7, 15, 5) Then
		    mLastError = libcURL.Errors.FEATURE_UNAVAILABLE
		    Return False
		  End If
		  
		  ' The form will be serialized one element at a time via several invocations of FormGetCallback
		  If FormGetStreams = Nil Then FormGetStreams = New Dictionary
		  If WriteTo <> Nil Then
		    FormGetStreams.Value(mHandle) = WriteTo
		  Else
		    FormGetStreams.Value(mHandle) = Me
		  End If
		  Try
		    mLastError = curl_formget(mHandle, mHandle, AddressOf FormGetCallback)
		  Finally
		    FormGetStreams.Remove(mHandle)
		  End Try
		  Return mLastError = 0
		End Function
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event SerializePart(Data As MemoryBlock, Length As Integer) As Integer
	#tag EndHook


	#tag Note, Name = Using this class
		This class represents a linked list of form elements that are managed by libcURL.
		Use the AddElement method to add a form element to the form. Form elements may be
		either strings or folderitems (for uploading)
		
		Once the form is constructed you can pass it to the EasyHandle.SetOption method using
		libcURL.Opts.HTTPPOST as the option number.
		
		e.g.
		
		  Dim frm As New libcURL.MultipartForm
		  Dim f FolderItem //assume a valid & extant file
		  Call frm.AddElement("file", f)
		  Call frm.AddElement("username", "AzureDiamond")
		  Call frm.AddElement("password", "hunter2")
		  Dim sock As New libcURL.EasyHandle
		  Call sock.SetOption(libcURL.Opts.HTTPPOST, frm)
		  Call sock.Perform("http://www.example.com/submit.php", 5)
	#tag EndNote


	#tag ComputedProperty, Flags = &h1
		#tag Getter
			Get
			  ' Returns a reference to the first element in the form. If the form is empty then
			  ' this method returns Nil.
			  
			  Dim List As Ptr = Ptr(Me.Handle)
			  If List = Nil Then Return Nil
			  Return New MultipartFormElement(List, Me)
			  
			  
			End Get
		#tag EndGetter
		Protected FirstItem As libcURL.MultipartFormElement
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private Shared FormGetStreams As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected LastItem As Ptr
	#tag EndProperty

	#tag Property, Flags = &h1
		#tag Note
			This array merely holds references to any header lists being used, to prevent them from going out of scope too early.
		#tag EndNote
		Protected mAdditionalHeaders() As libcURL.ListPtr
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mStreams() As libcURL.EasyHandle
	#tag EndProperty


	#tag Constant, Name = CURLFORM_BUFFER, Type = Double, Dynamic = False, Default = \"11", Scope = Public
	#tag EndConstant

	#tag Constant, Name = CURLFORM_BUFFERLENGTH, Type = Double, Dynamic = False, Default = \"13", Scope = Public
	#tag EndConstant

	#tag Constant, Name = CURLFORM_BUFFERPTR, Type = Double, Dynamic = False, Default = \"12", Scope = Public
	#tag EndConstant

	#tag Constant, Name = CURLFORM_CONTENTHEADER, Type = Double, Dynamic = False, Default = \"15", Scope = Public
	#tag EndConstant

	#tag Constant, Name = CURLFORM_CONTENTLEN, Type = Double, Dynamic = False, Default = \"20", Scope = Public
	#tag EndConstant

	#tag Constant, Name = CURLFORM_CONTENTSLENGTH, Type = Double, Dynamic = False, Default = \"6", Scope = Public
	#tag EndConstant

	#tag Constant, Name = CURLFORM_CONTENTTYPE, Type = Double, Dynamic = False, Default = \"14", Scope = Public
	#tag EndConstant

	#tag Constant, Name = CURLFORM_COPYCONTENTS, Type = Double, Dynamic = False, Default = \"4", Scope = Public
	#tag EndConstant

	#tag Constant, Name = CURLFORM_COPYNAME, Type = Double, Dynamic = False, Default = \"1", Scope = Public
	#tag EndConstant

	#tag Constant, Name = CURLFORM_END, Type = Double, Dynamic = False, Default = \"17", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = CURLFORM_FILE, Type = Double, Dynamic = False, Default = \"10", Scope = Public
	#tag EndConstant

	#tag Constant, Name = CURLFORM_FILECONTENT, Type = Double, Dynamic = False, Default = \"7", Scope = Public
	#tag EndConstant

	#tag Constant, Name = CURLFORM_FILENAME, Type = Double, Dynamic = False, Default = \"16", Scope = Public
	#tag EndConstant

	#tag Constant, Name = CURLFORM_STREAM, Type = Double, Dynamic = False, Default = \"19", Scope = Public
	#tag EndConstant


	#tag ViewBehavior
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			InheritedFrom="Object"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
