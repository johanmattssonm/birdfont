/*
 * libgit2 Vala binding
 *
 * Homepage: http://libgit2.github.com/
 * VAPI Homepage: https://github.com/apmasell/vapis/blob/master/libgit2.vapi
 * VAPI Maintainer: Andre Masella <andre@masella.name>
 *
 * This file is part of libgit2, distributed under the GNU GPL v2 with
 * a Linking Exception. For full terms see the included COPYING file.
 */

/**
 * Library to access the contents of git repositories
 *
 * libgit2 can access and manipulate the contents of git repositories. To begin, create an instance of a {@link Git.Repository} like so:
 * {{{
 * Git.Repository? repo;
 * if (Git.Repository.open(out repo, "/path/to/repo") != Git.Error.OK) {
 * stderr.printf("Could not open repository because: %s\n", Git.ErrorInfo.get_last().message);
 * return false;
 * }
 * }}}
 * Then use the methods of //repo// to access the repository.
 */
[CCode(cheader_filename = "git2.h")]
namespace Git {
	namespace Configuration {
		/**
		 * Generic backend that implements the interface to
		 * access a configuration file
		 */
		[CCode(cname = "git_config_backend", has_type_id = false, default_value = "GIT_CONFIG_BACKEND_INIT")]
		public struct backend {
			[CCode(cname = "GIT_CONFIG_BACKEND_VERSION")]
			public const uint VERSION;
			public uint version;
			public unowned Config cfg;
			public Delete @delete;
			[CCode(cname = "foreach")]
			public ForEach for_each;
			public Free free;
			public Get @get;
			[CCode(cname = "get_multivar")]
			public GetMulti get_multi;
			[CCode(cname = "refersh")]
			public Refresh refresh;
			public Open open;
			public Set @set;
			public SetMulti set_multi;
		}

		[CCode(cname = "git_config_file_delete_cb", has_type_id = false, has_target = false)]
		public delegate int Delete(backend backend, string key);
		[CCode(cname = "git_config_file_foreach_cb", has_type_id = false, has_target = false)]
		public delegate int ForEach(backend backend, string regex, ConfigForEach config_for_each);
		[CCode(cname = "git_config_file_free_cb", has_type_id = false, has_target = false)]
		public delegate void Free(backend backend);
		[CCode(cname = "git_config_file_get_cb", has_type_id = false, has_target = false)]
		public delegate int Get(backend backend, string key, out string value);
		[CCode(cname = "git_config_file_get_mulivar_cb", has_type_id = false, has_target = false)]
		public delegate int GetMulti(backend backend, string key, string? regexp, Setter func);
		[CCode(cname = "git_config_file_refresh", has_type_id = false, has_target = false)]
		public delegate Error Refresh(backend backend);
		[CCode(cname = "git_config_file_set_cb", has_type_id = false, has_target = false)]
		public delegate int Setter(string val);
		[CCode(cname = "git_config_file_open_cb", has_type_id = false, has_target = false)]
		public delegate int Open(backend backend);
		[CCode(cname = "git_config_file_set_cb", has_type_id = false, has_target = false)]
		public delegate int Set(backend backend, string key, string value);
		[CCode(cname = "git_config_file_set_multivar_cb", has_type_id = false, has_target = false)]
		public delegate int SetMulti(backend backend, string name, string regexp, string val);
	}
	namespace Database {
		/**
		 * An open object database handle
		 */
		[CCode(cname = "git_odb", free_function = "git_odb_close", has_type_id = false)]
		[Compact]
		public class Handle {
			/**
			 * Create a new object database with no backends.
			 *
			 * Before the ODB can be used for read/writing, a custom database
			 * backend must be manually added using {@link Handle.add_backend}.
			 *
			 * @param db location to store the database pointer, if opened. Set to null if the open failed.
			 */
			[CCode(cname = "git_odb_new")]
			public static Error create(out Handle? db);

			/**
			 * Create a new object database and automatically add
			 * the two default backends.
			 *
			 * Automatically added are:
			 * - {@link backend.create_loose}: read and write loose object files
			 * from disk, assuming //objects_dir// as the Objects folder
			 *
			 * - {@link backend.create_pack}: read objects from packfiles,
			 * assuming //objects_dir// as the Objects folder which
			 * contains a //pack// folder with the corresponding data
			 *
			 * @param db location to store the database pointer, if opened.
			 * Set to null if the open failed.
			 * @param objects_dir path of the backends' //objects// directory.
			 */
			[CCode(cname = "git_odb_open")]
			public static Error open(out Handle db, string objects_dir);

			/**
			 * Add a custom backend to an existing Object DB; this
			 * backend will work as an alternate.
			 *
			 * Alternate backends are always checked for objects ''after''
			 * all the main backends have been exhausted.
			 *
			 * The backends are checked in relative ordering, based on the
			 * value of the //priority// parameter.
			 *
			 * Writing is disabled on alternate backends.
			 *
			 * @param backend the backend instance
			 * @param priority Value for ordering the backends queue
			 */
			[CCode(cname = "git_odb_add_alternate")]
			public Error add_alternate(backend backend, int priority);

			/**
			 * Add a custom backend to an existing Object DB
			 *
			 * The backends are checked in relative ordering, based on the
			 * value of the //priority// parameter.
			 * @param backend the backend instance
			 * @param priority Value for ordering the backends queue
			 */
			[CCode(cname = "git_odb_add_backend")]
			public Error add_backend(backend backend, int priority);

			/**
			 * Determine if the given object can be found in the object database.
			 *
			 * @param id the object to search for.
			 */
			[CCode(cname = "git_odb_exists")]
			public bool contains(object_id id);

			/**
			 * Create a "fake" repository to wrap an object database
			 *
			 * Create a repository object to wrap an object database to be used with
			 * the API when all you have is an object database. This doesn't have any
			 * paths associated with it, so use with care.
			 */
			[CCode(cname = "git_repository_wrap_odb", instance_pos = -1)]
			public Error create_repository(out Repository? repository);

			/**
			 * List all objects available in the database
			 *
			 * The callback will be called for each object available in the
			 * database. Note that the objects are likely to be returned in the index
			 * order, which would make accessing the objects in that order inefficient.
			 */
			[CCode(cname = "git_odb_foreach")]
			public Error for_each(ObjectIdForEach object_for_each);

			/**
			 * Read an object from the database.
			 *
			 * This method queries all available ODB backends
			 * trying to read the given id.
			 *
			 * @param obj pointer where to store the read object
			 * @param id identity of the object to read.
			 */
			[CCode(cname = "git_odb_read", instance_pos = 1.2)]
			public Error read(out Object obj, object_id id);

			/**
			 * Read an object from the database, given a prefix
			 * of its identifier.
			 *
			 * This method queries all available ODB backends
			 * trying to match the //len// first hexadecimal
			 * characters of the //short_id//.
			 * The remaining //({@link object_id.HEX_SIZE}-len)*4// bits of
			 * //short_id// must be 0s.
			 * //len// must be at least {@link object_id.MIN_PREFIX_LENGTH},
			 * and the prefix must be long enough to identify
			 * a unique object in all the backends; the
			 * method will fail otherwise.
			 *
			 * The returned object is reference counted and
			 * internally cached, so it should be closed
			 * by the user once it's no longer in use.
			 *
			 * @param obj pointer where to store the read object
			 * @param short_id a prefix of the id of the object to read.
			 * @param len the length of the prefix
			 */
			[CCode(cname = "git_odb_read_prefix", instance_pos = 1.2)]
			public Error read_by_prefix(out Object obj, object_id short_id, size_t len);

			/**
			 * Read the header of an object from the database, without
			 * reading its full contents.
			 *
			 * The header includes the length and the type of an object.
			 *
			 * Note that most backends do not support reading only the header
			 * of an object, so the whole object will be read and then the
			 * header will be returned.
			 *
			 * @param len the length of the object
			 * @param type the type of the object
			 * @param id identity of the object to read.
			 */
			[CCode(cname = "git_odb_read_header", instance_pos = 2.3)]
			public Error read_header(out size_t len, out ObjectType type, object_id id);

			/**
			 * Refresh the object database to load newly added files.
			 *
			 * If the object databases have changed on disk while the library is
			 * running, this function will force a reload of the underlying indexes.
			 *
			 * Use this function when you're confident that an external application
			 * has tampered with the ODB.
			 *
			 * Note that it is not necessary to call this function at all. The
			 * library will automatically attempt to refresh the ODB when a lookup
			 * fails, to see if the looked up object exists on disk but hasn't been
			 * loaded yet.
			 */
			[CCode(cname = "git_odb_refresh")]
			public Error refresh();

			/**
			 * Open a stream to write an object into the ODB
			 *
			 * The type and final length of the object must be specified
			 * when opening the stream.
			 *
			 * The returned stream will be of type {@link StreamMode.WRONLY} and
			 * will have the following methods:
			 *
			 * * {@link stream.write}: write //n// bytes into the stream
			 * * {@link stream.finalize_write}: close the stream and store the object in the ODB
			 *
			 * The streaming write won't be effective until {@link stream.finalize_write}
			 * is called and returns without an error
			 *
			 * @param stream where to store the stream
			 * @param size final size of the object that will be written
			 * @param type type of the object that will be written
			 */
			[CCode(cname = "git_odb_open_wstream", instance_pos = 1.2)]
			public Error open_write_stream(out stream stream, size_t size, ObjectType type);

			/**
			 * Open a stream to read an object from the ODB
			 *
			 * Note that most backends do ''not'' support streaming reads
			 * because they store their objects as compressed/delta'ed blobs.
			 *
			 * It's recommended to use {@link Handle.read} instead, which is
			 * assured to work on all backends.
			 *
			 * The returned stream will be of type {@link StreamMode.RDONLY} and
			 * will have the following methods:
			 *
			 * * {@link stream.read}: read //n// bytes from the stream
			 *
			 * @param stream where to store the stream
			 * @param id id of the object the stream will read from
			 */
			[CCode(cname = "git_odb_open_rstream")]
			public Error open_read_stream(out stream stream, object_id id);

			/**
			 * Write an object directly into the ODB
			 *
			 * This method writes a full object straight into the ODB.
			 * For most cases, it is preferred to write objects through a write
			 * stream, which is both faster and less memory intensive, specially
			 * for big objects.
			 *
			 * This method is provided for compatibility with custom backends
			 * which are not able to support streaming writes
			 *
			 * @param id pointer to store the id result of the write
			 * @param data buffer with the data to store
			 * @param type type of the data to store
			 */
			[CCode(cname = "git_odb_write", instance_pos = 1.2)]
			public Error write(object_id id, [CCode(array_length_Type = "size_t")] uint8[] data, ObjectType type);
		}

		/**
		 * An object read from the database
		 */
		[CCode(cname = "git_odb_object", free_function = "git_odb_object_free", has_type_id = false)]
		[Compact]
		public class Object {

			/**
			 * The data of an ODB object
			 *
			 * This is the uncompressed, raw data as read from the ODB,
			 * without the leading header.
			 */
			public uint8[] data {
				[CCode(cname = "git_odb_object_data", array_length_cexpr = "git_odb_object_size")]
				get;
			}

			/**
			 * The id of an ODB object
			 */
			public object_id? id {
				[CCode(cname = "git_odb_object_id")]
				get;
			}

			/**
			 * The type of an ODB object
			 */
			public ObjectType type {
				[CCode(cname = "git_odb_object_type")]
				get;
			}
		}

		/**
		 * A custom backend in an ODB
		 */
		[CCode(cname = "git_odb_backend", has_type_id = false, default_value = "GIT_ODB_BACKEND_INIT")]
		public struct backend {
			[CCode(cname = "GIT_ODB_BACKEND_VERSION")]
			public const uint VERSION;
			public uint version;
			public unowned Handle odb;

			public BackendExists exists;
			public BackendFree free;
			[CCode(cname = "foreach")]
			public BackendForEach for_each;
			public BackendRead read;
			public BackendReadHeader read_header;
			public BackendReadPrefix read_prefix;
			[CCode(cname = "readstream")]
			public BackendReadStream read_stream;
			public BackendWrite write;
			public BackendWritePack write_pack;
			[CCode(cname = "writestream")]
			public BackendWriteStream write_stream;

			[CCode(cname = "git_odb_backend_loose")]
			public static Error create_loose(out backend backend, string objects_dir);
			[CCode(cname = "git_odb_backend_one_pack")]
			public static Error create_one_pack(out backend backend, string index_file);
			[CCode(cname = "git_odb_backend_pack")]
			public static Error create_pack(out backend backend, string objects_dir);
			[CCode(cname = "git_odb_backend_malloc", simple_generics = true)]
			public T malloc<T>(size_t len);
		}

		/**
		 * A stream to read/write from the ODB
		 */
		[CCode(cname = "git_odb_stream", has_type_id = false)]
		public struct stream {
			public unowned backend? backend;

			public StreamMode mode;

			public StreamFinalizeWrite finalize_write;
			public StreamFree free;
			public StreamRead read;
			public StreamWrite write;
		}
		/**
		 * A stream to write a pack file to the ODB
		 */
		[CCode(cname = "git_odb_writepack", has_type_id = false)]
		public struct write_pack {
			public unowned backend? backend;
			[CCode(cname = "add")]
			public WritePackAdd add;
			[CCode(cname = "commit")]
			public WritePackCommit commit;
			[CCode(cname = "free")]
			public WritePackFree free;
		}
		/**
		 * Streaming mode
		 */
		[CCode(cname = "git_odb_streammode", cprefix = "GIT_STREAM_", has_type_id = false)]
		public enum StreamMode {
			RDONLY,
			WRONLY,
			RW
		}
		[CCode(has_target = false, has_type_id = false)]
		public delegate bool BackendExists(backend self, object_id id);
		[CCode(has_target = false, has_type_id = false)]
		public delegate void BackendFree(backend self);
		[CCode(has_target = false, has_type_id = false)]
		public delegate Error BackendForEach(backend self, ObjectIdForEach cb);
		/**
		 * Read each return to libgit2 a buffer which will be freed later.
		 *
		 * The buffer should be allocated using the function {@link backend.malloc} to
		 * ensure that it can be safely freed later.
		 */
		[CCode(has_target = false, has_type_id = false)]
		public delegate Error BackendRead([CCode(array_length_type = "size_t")] out uint8[] data, out ObjectType type, backend self, object_id id);
		/**
		 * Find a unique object given a prefix
		 *
		 * The id given must be so that the remaining
		 * ({@link object_id.HEX_SIZE} - len)*4 bits are 0s.
		 */
		[CCode(has_target = false, has_type_id = false)]
		public delegate Error BackendReadHeader(out size_t size, out ObjectType type, backend self, object_id id);
		[CCode(has_target = false, has_type_id = false)]
		public delegate Error BackendReadPrefix(out object_id id, [CCode(array_length_type = "size_t")] out uint8[] data, out ObjectType type, backend self, object_id id_prefix, size_t len);
		[CCode(has_target = false, has_type_id = false)]
		public delegate Error BackendReadStream(out stream stream, backend self, object_id id);
		[CCode(has_target = false, has_type_id = false)]
		public delegate Error BackendWrite(out object_id id, backend self, [CCode(array_length_type = "size_t")] out uint8[] data, ObjectType type);
		[CCode(has_target = false, has_type_id = false)]
		public delegate Error BackendWriteStream(out stream stream, backend self, size_t size, ObjectType type);
		[CCode(has_target = false, has_type_id = false)]
		public delegate int BackendWritePack(out write_pack write_pack, backend self, TransferProgress progress);

		[CCode(has_target = false, has_type_id = false)]
		public delegate Error StreamFinalizeWrite(out object_id id, stream stream);
		[CCode(has_target = false, has_type_id = false)]
		public delegate void StreamFree(stream stream);
		[CCode(has_target = false, has_type_id = false)]
		public delegate int StreamRead(stream stream, [CCode(array_length_type = "size_t")] uint8[] buffer);
		[CCode(has_target = false, has_type_id = false)]
		public delegate int StreamWrite(stream stream, [CCode(array_length_type = "size_t")] uint8[] buffer);

		[CCode(has_target = false)]
		public delegate int WritePackAdd(write_pack write_pack, [CCode(array_length_type = "size_t")] uint8[] data, transfer_progress stats);
		[CCode(has_target = false)]
		public delegate int WritePackCommit(write_pack write_pack, transfer_progress stats);
		[CCode(has_target = false)]
		public delegate void WritePackFree(write_pack write_pack);
	}
	namespace Threads {
		/**
		 * Init the threading system.
		 *
		 * If libgit2 has been built with GIT_THREADS
		 * on, this function must be called once before
		 * any other library functions.
		 *
		 * If libgit2 has been built without GIT_THREADS
		 * support, this function is a no-op.
		 */
		[CCode(cname = "git_threads_init")]
		public Error init();

		/**
		 * Shutdown the threading system.
		 *
		 * If libgit2 has been built with GIT_THREADS
		 * on, this function must be called before shutting
		 * down the library.
		 *
		 * If libgit2 has been built without GIT_THREADS
		 * support, this function is a no-op.
		 */
		[CCode(cname = "git_threads_shutdown")]
		public void shutdown();
	}
	namespace Version {
		[CCode(cname = "LIBGIT2_VERSION")]
		public const string VERSION;
		[CCode(cname = "LIBGIT2_VER_MAJOR")]
		public const int MAJOR;
		[CCode(cname = "LIBGIT2_VER_MINOR")]
		public const int MINOR;
		[CCode(cname = "LIBGIT2_VER_REVISION")]
		public const int REVISION;
		/**
		 * Return the version of the libgit2 library
		 * being currently used.
		 *
		 * @param major Store the major version number
		 * @param minor Store the minor version number
		 * @param rev Store the revision (patch) number
		 */
		[CCode(cname = "git_libgit2_version")]
		public void get_version(out int major, out int minor, out int rev);
	}

	/*
	 * Attribute management routines
	 */
	[CCode(cname = "git_repository", cheader_filename = "git2/attr.h", has_type_id = false)]
	public class Attr {
		[CCode(cname = "git_attr_t", cprefix = "GIT_ATTR_", has_type_id = false)]
		public enum AttrType {
			[CCode(cname = "GIT_ATTR_UNSPECIFIED_T")]
			UNSPECIFIED,
			[CCode(cname = "GIT_ATTR_TRUE_T")]
			TRUE,
			[CCode(cname = "GIT_ATTR_FALSE_T")]
			FALSE,
			[CCode(cname = "GIT_ATTR_VALUE_T")]
			VALUE;
			/**
			 * Return the value type for a given attribute.
			 *
			 * This can be either {@link TRUE}, {@link FALSE}, {@link UNSPECIFIED}
			 * (if the attribute was not set at all), or {@link VALUE}, if the
			 * attribute was set to an actual string.
			 *
			 * If the attribute has a {@link VALUE} string, it can be accessed
			 * normally as a string.
			 */
			[CCode(cname = "git_attr_value")]
			public static AttrType from(string attr);
		}

		/**
		 * Checks if an attribute is set on.
		 *
		 * In core git parlance, this the value for "Set" attributes.
		 */
		[CCode(cname = "GIT_ATTR_TRUE")]
		public static bool is_true(string? attr);
		/**
		 * Checks if an attribute is set off.
		 *
		 * In core git parlance, this is the value for attributes that are "Unset"
		 * (not to be confused with values that a "Unspecified").
		 */
		[CCode(cname = "GIT_ATTR_FALSE")]
		public static bool is_false(string? attr);
		/**
		 * Checks if an attribute is set to a value (as opposied to TRUE, FALSE or
		 * UNSPECIFIED).
		 */
		[CCode(cname = "GIT_ATTR_SET_TO_VALUE")]
		public static bool is_set(string? attr);
		/*
		 * Checks if an attribute is unspecified. This may be due to the attribute
		 * not being mentioned at all or because the attribute was explicitly set
		 * unspecified via the `!` operator.
		 */
		[CCode(cname = "GIT_ATTR_UNSPECIFIED")]
		public static bool is_unspecified(string? attr);

		/**
		 * Add a macro definition.
		 *
		 * Macros will automatically be loaded from the top level .gitattributes
		 * file of the repository (plus the build-in "binary" macro). This
		 * function allows you to add others. For example, to add the default
		 * macro, you would call:
		 * {{{
		 * repo.attributes.add_macro("binary", "-diff -crlf");
		 * }}}
		 */
		[CCode(cname = "git_attr_add_macro")]
		public Error add_macro(string name, string val);

		/**
		 * Lookup attribute for path returning string caller must free
		 */
		[CCode(cname = "git_attr_get")]
		public Error lookup(AttrCheck flags, string path, string name, out unowned string? val);

		/**
		 * Lookup list of attributes for path, populating array of strings
		 *
		 * Use this if you have a known list of attributes that you want to
		 * look up in a single call. This is somewhat more efficient than
		 * calling {@link lookup} multiple times.
		 *
		 * For example, you might write:
		 * {{{
		 * string attrs[] = { "crlf", "diff", "foo" };
		 * string results[];
		 * repo.attributes.lookup_many(AttrCheck.FILE_THEN_INDEX, "my/fun/file.c", attrs, out values);
		 * }}}
		 * Then you could loop through the 3 values to get the settings for
		 * the three attributes you asked about.
		 *
		 * @param path The path inside the repo to check attributes. This does not
		 * have to exist, but if it does not, then it will be treated as a plain
		 * file (i.e. not a directory).
		 * @param names The attribute names.
		 * @param values The values of the attributes.
		 */
		[CCode(cname = "_vala_git_attr_get_many")]
		public Error lookup_many(AttrCheck flags, string path, string[] names, out string[] values) {
			unstr[] temp = new unstr[names.length];
			var e = _lookup_many(flags, path, names, temp);
			values = new string[names.length];
			for (var it = 0; it < temp.length; it++) {
				values[it] = temp[it].dup();
			}
			return e;
		}

		[CCode(cname = "git_attr_get_many")]
		private Error _lookup_many(AttrCheck flags, string path, [CCode(array_length_pos = 2.1, array_length_type = "size_t")] string[] names, void* values);

		/**
		 * Perform an operation on each attribute of a path.
		 * @param path The path inside the repo to check attributes. This does not
		 * have to exist, but if it does not, then it will be treated as a plain
		 * file (i.e. not a directory).
		 * @param attribute_for_each The function that will be invoked on each
		 * attribute and attribute value. The name parameter will be the name of
		 * the attribute and the value will be the value it is set to, including
		 * possibly null if the attribute is explicitly set to UNSPECIFIED using
		 * the ! sign. This will be invoked only once per attribute name, even if
		 * there are multiple rules for a given file. The highest priority rule
		 * will be used.
		 */
		[CCode(cname = "git_attr_foreach")]
		public Error for_each(AttrCheck flags, string path, AttributeForEach attribute_for_each);

		/**
		 * Flush the gitattributes cache.
		 *
		 * Call this if you have reason to believe that the attributes files
		 * on disk no longer match the cached contents of memory. This will cause
		 * the attributes files to be reloaded the next time that an attribute
		 * access function is called.
		 */
		[CCode(cname = "git_attr_cache_flush")]
		public void flush();
	}

	/**
	 * In-memory representation of a blob object.
	 */
	[CCode(cname = "git_blob", free_function = "git_blob_free", has_type_id = false)]
	[Compact]
	public class Blob : Object {
		[CCode(array_length = false, cname = "git_blob_rawcontent")]
		private unowned uint8[]? _get_content();

		/**
		 * Get a read-only buffer with the raw content of a blob.
		 *
		 * A pointer to the raw content of a blob is returned.
		 * The pointer may be invalidated at a later time.
		 */
		public uint8[]? content {
			get {
				unowned uint8[]? content = _get_content();
				if (content != null) {
					((!)content).length = (int) size;
				}
				return content;
			}
		}
		/**
		 * The id of a blob.
		 */
		public object_id? id {
			[CCode(cname = "git_blob_id")]
			get;
		}
		/**
		 * Determine if the blob content is most certainly binary or not.
		 *
		 * The heuristic used to guess if a file is binary is taken from core git:
		 * Searching for NUL bytes and looking for a reasonable ratio of printable
		 * to non-printable characters among the first 4000 bytes.
		 */
		public bool is_binary {
			[CCode(cname = "git_blob_is_binary")]
			get;
		}

		/**
		 * Get the size in bytes of the contents of a blob
		 */
		public size_t size {
			[CCode(cname = "git_blob_rawsize")]
			get;
		}
		/**
		 * Directly run a text diff on two blobs.
		 *
		 * Compared to a file, a blob lacks some contextual information. As such, the
		 * {@link diff_file} parameters of the callbacks will be filled accordingly to the following:
		 * mode will be set to 0, path will be null. When dealing with a null blob, object id
		 * will be set to 0.
		 *
		 * When at least one of the blobs being dealt with is binary, the {@link diff_delta} binary
		 * attribute will be set to true and no call to the hunk nor line will be made.
		 *
		 * We do run a binary content check on the two blobs and if either of the
		 * blobs looks like binary data, {@link diff_delta.flags} will {@link DiffFlag.BINARY}
		 * and no call to the {@link DiffHunk} nor {@link DiffData} will be made
		 * (unless you pass {@link DiffFlags.FORCE_TEXT} of course).
		 */
		[CCode(cname = "git_diff_blobs", simple_generics = true)]
		public Error diff<T>(Blob new_blob, diff_options options, DiffFile<T> file, DiffHunk<T> hunk, DiffData<T> line, T context);
		/**
		 * Directly run a diff between a blob and a buffer.
		 *
		 * As with {@link diff}, comparing a blob and buffer lacks some context, so
		 * the {@link diff_file} parameters to the callbacks will be faked.
		 */
		[CCode(cname = "git_diff_blob_to_buffer", simple_generics = true)]
		public Error diff_buffer<T>([CCode(array_length_type = "size_t")] uint8[] buffer, diff_options options, DiffFile<T> file, DiffHunk<T> hunk, DiffData<T> line, T context);
	}

	/**
	 * Parsed representation of a commit object.
	 */
	[CCode(cname = "git_commit", free_function = "git_commit_free", has_type_id = false)]
	[Compact]
	public class Commit : Object {
		/**
		 * The author of a commit.
		 */
		public Signature author {
			[CCode(cname = "git_commit_author")]
			get;
		}

		/**
		 * The committer of a commit.
		 */
		public Signature committer {
			[CCode(cname = "git_commit_committer")]
			get;
		}

		/**
		 * The id of a commit.
		 */
		public object_id? id {
			[CCode(cname = "git_commit_id")]
			get;
		}

		/**
		 * The full message of a commit.
		 */
		public string message {
			[CCode(cname = "git_commit_message")]
			get;
		}

		/**
		 * The encoding for the message of a commit, as a string representing a
		 * standard encoding name.
		 *
		 * The encoding may be null if the encoding header in the commit is
		 * missing; in that case UTF-8 is assumed.
		 */
		public string? message_encoding {
			[CCode(cname = "git_commit_message_encoding")]
			get;
		}

		/**
		 * The parent(s) of this commit
		 *
		 * Typically, commits have a single parent, but merges can have many.
		 */
		public Parents parents {
			[CCode(cname = "")]
			get;
		}

		/**
		 * Get the commit time (i.e., committer time) of a commit.
		 */
		public int64 time {
			[CCode(cname = "git_commit_time")]
			get;
		}

		/**
		 * Get the commit timezone offset (i.e., committer's preferred timezone) in minutes from UTC of a commit.
		 */
		public int time_offset {
			[CCode(cname = "git_commit_time_offset")]
			get;
		}

		/**
		 * Get the id of the tree pointed to by a commit.
		 *
		 * This differs from {@link lookup_tree} in that no attempts
		 * are made to fetch an object from the ODB.
		 */
		public object_id? tree_id {
			[CCode(cname = "git_commit_tree_oid")]
			get;
		}
		/**
		 * Get the commit object that is an ancestor of the named commit object,
		 * following only the first parents.
		 *
		 * @param ancestor the ancestor received, if any
		 * @param n the requested generation, or 0 for a copy of the commit.
		 */
		[CCode(cname = "git_commit_nth_gen_ancestor", instance_pos = 1.2)]
		public Error get_ancestor(out Commit? ancestor, uint n);

		/**
		 * The message of a commit converted to UTF-8.
		 */
		public string? get_message_utf8() throws GLib.ConvertError {
			return this.message_encoding == null ? this.message : GLib.convert(this.message, this.message.length, "utf-8", (!) this.message_encoding);
		}

		/**
		 * Get the tree pointed to by a commit.
		 */
		[CCode(cname = "git_commit_tree", instance_pos = -1)]
		public Error lookup_tree(out Tree tree);
	}

	/**
	 * Memory representation of a set of config files
	 */
	[CCode(cname = "git_config", free_function = "git_config_free", has_type_id = false)]
	[Compact]
	public class Config {
		/**
		 * Allocate a new configuration object
		 *
		 * This object is empty, so you have to add a file to it before you can do
		 * anything with it.
		 *
		 * @param config the new configuration
		 */
		[CCode(cname = "git_config_new")]
		public static Error create(out Config config);

		/**
		 * Locate the path to the global configuration file
		 *
		 * The user or global configuration file is usually located in
		 * //$HOME/.gitconfig//.
		 *
		 * This method will try to guess the full path to that file, if the file
		 * exists. The returned path may be used on any call to load the global
		 * configuration file.
		 *
		 * @param config_path Buffer store the path
		 * @return {@link Error.OK} if a global configuration file has been found.
		 */
		[CCode(cname = "git_config_find_global")]
		public static Error find_global([CCode(array_length_type = "size_t")] char[] config_path);
		/**
		 * Locate the path to the global xdg compatible configuration file
		 *
		 * The xdg compatible configuration file is usually located in
		 * //$HOME/.config/git/config//.
		 *
		 * This method will try to guess the full path to that file, if the file
		 * exists.
		 * @param config_path Buffer store the path
		 * @return {@link Error.OK} if an XDG configuration file has been found.
		 */
		[CCode(cname = "git_config_find_xdg")]
		public static Error find_xdg([CCode(array_length_type = "size_t")] char[] config_path);

		/**
		 * Locate the path to the system configuration file
		 *
		 * If /etc/gitconfig doesn't exist, it will look for
		 * %PROGRAMFILES%\Git\etc\gitconfig.
		 * @param config_path Buffer of {@link PATH_MAX} length to store the path
		 * @return {@link Error.OK} if a system configuration file has been found. Its path will be stored in //buffer//.
		 */
		[CCode(cname = "git_config_find_system")]
		public static Error find_system([CCode(array_length_type = "size_t")] char[] config_path);


		/**
		 * Maps a string value to an integer constant
		 */
		[CCode(cname = "git_config_lookup_map_value")]
		public static Error lookup_map_value(out int result, [CCode(array_length_type = "size_t")] config_var_map[] map, string name);

		/**
		 * Create a new config instance containing a single on-disk file
		 *
		 * This method is a simple utility wrapper for the following sequence of
		 * calls:
		 * * {@link create}
		 * * {@link add_filename}
		 *
		 * @param cfg the configuration instance to create
		 * @param path path to the on-disk file to open
		 */
		[CCode(cname = "git_config_open_ondisk")]
		public static Error open(out Config? cfg, string path);

		/**
		 * Open the global and system configuration files
		 *
		 * Utility wrapper that calls {@link find_global}, {@link find_xdg}, and
		 * {@link find_system} and opens the located file, if it exists.
		 *
		 * @param config where to store the config instance
		 */
		[CCode(cname = "git_config_open_default")]
		public static Error open_default(out Config? config);

		/**
		 * Build a single-level focused config object from a multi-level one.
		 *
		 * The returned config object can be used to perform get/set/delete
		 * operations on a single specific level.
		 *
		 * Getting several times the same level from the same parent multi-level
		 * config will return different config instances, but containing the same
		 * config_file instance.
		 *
		 * @param parent Multi-level config to search for the given level
		 * @param level Configuration level to search for
		 */
		[CCode(cname = "git_config_open_level")]
		public static Error open_level(out Config? config, Config parent, ConfigLevel level);

		/**
		 * Parse a string value as a bool.
		 *
		 * Valid values for true are: 'true', 'yes', 'on', 1 or any number
		 * different from 0
		 *
		 * Valid values for false are: 'false', 'no', 'off', 0
		 */
		[CCode(cname = "git_config_parse_bool")]
		public static Error bool(out bool result, string @value);

		/**
		 * Parse a string value as an int32.
		 *
		 * An optional value suffix of 'k', 'm', or 'g' will cause the value to be
		 * multiplied by 1024, 1048576, or 1073741824 prior to output.
		 */
		[CCode(cname = "git_config_parse_int32")]
		public static Error parse_int32(out int32 result, string @value);

		/**
		 * Parse a string value as an int64.
		 *
		 * An optional value suffix of 'k', 'm', or 'g' will cause the value to be
		 * multiplied by 1024, 1048576, or 1073741824 prior to output.
		 */
		[CCode(cname = "git_config_parse_int64")]
		public static Error parse_int64(out int64 result, string @value);

		/**
		 * Add a generic config file instance to an existing config
		 *
		 * Further queries on this config object will access each of the config
		 * file instances in order (instances with a higher priority will be
		 * accessed first).
		 *
		 * @param backend the configuration file (backend) to add
		 * @param level the priority level of the backend
		 * @param force if a config file already exists for the given priority level, replace it
		 */
		[CCode(cname = "git_config_add_backend")]
		public Error add_backend(Configuration.backend backend, ConfigLevel level, bool force);

		/**
		 * Add an on-disk config file instance to an existing config
		 *
		 * The on-disk file pointed at by path will be opened and parsed; it's
		 * expected to be a native Git config file following the default Git config
		 * syntax (see man git-config).
		 *
		 * Further queries on this config object will access each of the config
		 * file instances in order (instances with a higher priority will be
		 * accessed first).
		 *
		 * @param path path to the configuration file (backend) to add
		 * @param level the priority the backend should have
		 */
		[CCode(cname = "git_config_add_file_ondisk")]
		public Error add_filename(string path, ConfigLevel level, bool force);

		/**
		 * Delete a config variable
		 *
		 * @param name the variable to delete
		 */
		[CCode(cname = "git_config_delete_entry")]
		public Error delete(string name);

		/**
		 * Perform an operation on each config variable.
		 *
		 * The callback receives the normalized name and value of each variable in
		 * the config backend. As soon as one of the callback functions returns
		 * something other than 0, this function returns that value.
		 *
		 * @param config_for_each the function to call on each variable
		 */
		[CCode(cname = "git_config_foreach")]
		public int for_each(ConfigForEach config_for_each);
		/**
		 * Perform an operation on each config variable matching a regular expression.
		 *
		 * This behaviors like {@link for_each} with an additional filter of a
		 * regular expression that filters which config keys are passed to the
		 * callback.
		 *
		 * @param regexp regular expression to match against config names
		 * @param config_for_each the function to call on each variable
		 * @return 0 or the return value of the callback which didn't return 0
		 */
		[CCode(cname = "git_config_foreach_match")]
		public int for_each_match(string regexp, ConfigForEach config_for_each);

		/**
		 * Get the value of a boolean config variable.
		 *
		 * @param name the variable's name
		 * @param value where the value should be stored
		 */
		[CCode(cname = "git_config_get_bool")]
		public Error get_bool(string name, out bool value);

		/**
		 * Get the entry of a config variable.
		 * @param name the variable's name
		 */
		[CCode(cname = "git_config_get_entry", instance_pos = 1.1)]
		public Error get_entry(out unowned config_entry? entry, string name);

		/**
		 * Get the value of an integer config variable.
		 *
		 * @param name the variable's name
		 * @param value where the value should be stored
		 */
		[CCode(cname = "git_config_get_int")]
		public Error get_int32(string name, out int32 value);

		/**
		 * Get the value of a long integer config variable.
		 *
		 * @param name the variable's name
		 * @param value where the value should be stored
		 */
		[CCode(cname = "git_config_get_int64")]
		public Error get_int64(string name, out int64 value);

		/**
		 * Get each value of a multivar.
		 *
		 * The callback will be called on each variable found
		 *
		 * @param name the variable's name
		 * @param regexp regular expression to filter which variables we're interested in. Use NULL to indicate all
		 * @param fn the function to be called on each value of the variable
		 */
		[CCode(cname = "git_config_get_multivar")]
		public Error get_multivar(string name, string? regexp, Configuration.Setter fn);

		/**
		 * Get the value of a string config variable.
		 *
		 * @param name the variable's name
		 * @param value the variable's value
		 */
		public Error get_string(string name, out unowned string value);

		/**
		 * Reload changed config files
		 *
		 * A config file may be changed on disk out from under the in-memory config
		 * object. This function causes us to look for files that have been
		 * modified since we last loaded them and refresh the config with the
		 * latest information.
		 */
		[CCode(cname = "git_config_refresh")]
		public Error refresh();
		/**
		 * Set the value of a boolean config variable.
		 *
		 * @param name the variable's name
		 * @param value the value to store
		 */
		[CCode(cname = "git_config_set_bool")]
		public Error set_bool(string name, bool value);

		/**
		 * Set the value of an integer config variable.
		 *
		 * @param name the variable's name
		 * @param value integer value for the variable
		 */
		[CCode(cname = "git_config_set_int32")]
		public Error set_int32(string name, int32 value);

		/**
		 * Set the value of a long integer config variable.
		 *
		 * @param name the variable's name
		 * @param value Long integer value for the variable
		 */
		[CCode(cname = "git_config_set_long64")]
		public Error set_int64(string name, int64 value);

		/**
		 * Set a multivar
		 *
		 * @param name the variable's name
		 * @param regexp a regular expression to indicate which values to replace
		 * @param value the new value.
		 */
		[CCode(cname = "git_config_set_multivar")]
		public Error set_multivar(string name, string regexp, string @value);
		/**
		 * Set the value of a string config variable.
		 *
		 * A copy of the string is made and the user is free to use it
		 * afterwards.
		 *
		 * @param name the variable's name
		 * @param value the string to store.
		 */
		[CCode(cname = "git_config_set_string")]
		public Error set_string(string name, string value);
		/**
		 * Query the value of a config variable and return it mapped to an integer
		 * constant.
		 *
		 * This is a helper method to easily map different possible values to a
		 * variable to integer constants that easily identify them.
		 *
		 * A mapping array looks as follows:
		 * {{{
		 * var autocrlf_mapping = Git.config_var_map[] {
		 * {Git.ConfigVar.FALSE, null, GIT_AUTO_CRLF_FALSE},
		 * {Git.ConfigVar.TRUE, null, GIT_AUTO_CRLF_TRUE},
		 * {Git.ConfigVar.STRING, "input", GIT_AUTO_CRLF_INPUT},
		 * {Git.ConfigVar.STRING, "default", GIT_AUTO_CRLF_DEFAULT}};
		 * }}}
		 *
		 * On any "false" value for the variable (e.g. "false", "FALSE", "no"), the
		 * mapping will store `GIT_AUTO_CRLF_FALSE` in the `out` parameter.
		 *
		 * The same thing applies for any "true" value such as "true", "yes" or "1", storing
		 * the `GIT_AUTO_CRLF_TRUE` variable.
		 *
		 * Otherwise, if the value matches the string "input" (with case insensitive comparison),
		 * the given constant will be stored in `out`, and likewise for "default".
		 *
		 * If not a single match can be made to store in `out`, an error code will be
		 * returned.
		 *
		 * @param name name of the config variable to lookup
		 * @param map array of objects specifying the possible mappings
		 * @param result place to store the result of the mapping
		 */
		[CCode(cname = "git_config_get_mapped", instance_pos = 1.1)]
		public Error get_mapped(out int result, string name, [CCode(array_length_type = "size_t")] config_var_map[] map);

	}
	/**
	 * The diff list object that contains all individual file deltas.
	 */
	[CCode(cname = "git_diff_list", free_function = "git_diff_list_free")]
	[Compact]
	public class DiffList {
		/**
		 * How many diff records are there in a diff list.
		 */
		public size_t num_deltas {
			[CCode(cname = "git_diff_num_deltas")]
			get;
		}
		/**
		 * Query how many diff records are there in a diff list.
		 * @param delta_t A delta type to filter the count, or -1 for all records
		 * @return Count of number of deltas matching delta_t type
		 */
		[CCode(cname = "git_diff_num_deltas_of_type")]
		public size_t get_count(DeltaType delta_t = DeltaType.ALL);
		/**
		 * Return the diff delta and patch for an entry in the diff list.
		 *
		 * For an unchanged file or a binary file, no patch will be created, and
		 * the {@link diff_delta.flags} will contain {@link DiffFlag.BINARY}.
		 *
		 * @param patch contains the text diffs for the delta.
		 * @param delta Output parameter for the delta object
		 * @param idx Index into diff list
		 */
		[CCode(cname = "git_diff_get_patch", instance_pos = 2.1)]
		public Error get_patch(out Patch? patch, out unowned diff_delta? delta, size_t idx);
		/**
		 * Merge one diff list into another.
		 *
		 * This merges items from the "from" list into the current list. The
		 * resulting diff list will have all items that appear in either list.
		 * If an item appears in both lists, then it will be "merged" to appear
		 * as if the old version was from the "onto" list and the new version
		 * is from the "from" list (with the exception that if the item has a
		 * pending DELETE in the middle, then it will show as deleted).
		 *
		 * @param from Diff to merge.
		 */
		[CCode(cname = "git_diff_merge")]
		public Error merge(DiffList from);

		/**
		 * Iterate over a diff list issuing callbacks.
		 *
		 * If the hunk and/or line callbacks are not null, then this will calculate
		 * text diffs for all files it thinks are not binary. If those are both
		 * null, then this will not bother with the text diffs, so it can be
		 * efficient.
		 */
		[CCode(cname = "git_diff_foreach", simple_generics = true)]
		public Error foreach<T>(DiffFile<T>? file, DiffHunk<T> hunk, DiffLine<T>? line, T context);

		/**
		 * Iterate over a diff generating text output like "git diff --name-status".
		 */
		[CCode(cname = "git_diff_print_compact")]
		public Error print_compact(DiffOutput print);

		/**
		 * Iterate over a diff generating text output like "git diff".
		 *
		 * This is a super easy way to generate a patch from a diff.
		 */
		[CCode(cname = "git_diff_print_patch")]
		public Error print_patch(DiffOutput print);
		/**
		 * Transform a diff list marking file renames, copies, etc.
		 *
		 * This modifies a diff list in place, replacing old entries that look like
		 * renames or copies with new entries reflecting those changes. This also
		 * will, if requested, break modified files into add/remove pairs if the
		 * amount of change is above a threshold.
		 *
		 * @param options Control how detection should be run, null for defaults
		 */
		[CCode(cname = "git_diff_find_similar")]
		public Error find_similar(find_options? options = null);
	}

	[CCode(cname = "git_error", has_type_id = false, free_function = "")]
	public class ErrorInfo {
		/**
		 * The explanation of the error.
		 */
		public string message;
		/**
		 * The error code.
		 */
		[CCode(cname = "klass")]
		public ErrClass @class;
		/**
		 * Return a detailed error string with the latest error
		 * that occurred in the library in this thread.
		 */
		[CCode(cname = "giterr_last")]
		public static unowned ErrorInfo? get_last();

		/**
		 * Clear the last library error for this thread.
		 */
		[CCode(cname = "giterr_clear")]
		public static void clear();
	}


	/**
	 * Object ID Shortener object
	 */
	[CCode(cname = "git_oid_shorten", free_function = "git_oid_shorten_free", has_type_id = false)]
	[Compact]
	public class IdShortener {
		/**
		 * Create a new id shortener.
		 *
		 * The id shortener is used to process a list of ids in text form and
		 * return the shortest length that would uniquely identify all of them.
		 *
		 * (e.g., look at the result of //git log --abbrev//)
		 *
		 * @param min_length The minimal length for all identifiers, which will be used even if shorter ids would still be unique.
		 */
		[CCode(cname = "git_oid_shorten_new")]
		public IdShortener(size_t min_length);

		/**
		 * Add a new id to set of shortened ids and calculate the minimal length to
		 * uniquely identify all the ids in the set.
		 *
		 * The id is expected to be a 40-char hexadecimal string.
		 *
		 * For performance reasons, there is a hard-limit of how many ids can be
		 * added to a single set (around ~22000, assuming a mostly randomized
		 * distribution), which should be enough for any kind of program, and keeps
		 * the algorithm fast and memory-efficient.
		 *
		 * Attempting to add more than those ids will result in a {@link ErrClass.NOMEMORY} error
		 *
		 * @param text_id an id in text form
		 * @return the minimal length to uniquely identify all ids added so far to the set; or an error code (<0) if an error occurs.
		 */
		[CCode(cname = "git_oid_shorten_add")]
		public int add(string text_id);
	}

	/**
	 * Memory representation of an index file.
	 */
	[CCode(cname = "git_index", free_function = "git_index_free", has_type_id = false)]
	[Compact]
	public class Index {
		/**
		 * Index capabilities flags.
		 */
		public IndexCapability capability {
			[CCode(cname = "git_index_caps")]
			get;
			[CCode(cname = "git_index_set_caps")]
			set;
		}

		/**
		 * Does the index contains entries representing file conflicts?
		 */
		public bool has_conflicts {
			[CCode(cname = "git_index_has_conflicts")]
			get;
		}

		public ReucIndex reuc {
			[CCode(cname = "")]
			get;
		}

		/**
		 * The repository this index relates to
		 */
		public Repository owner {
			[CCode(cname = "git_index_owner")]
			get;
		}

		/**
		 * The count of entries currently in the index
		 */
		public uint size {
			[CCode(cname = "git_index_entrycount")]
			get;
		}

		/**
		 * Create an in-memory index object.
		 *
		 * This index object cannot be read/written to the filesystem,
		 * but may be used to perform in-memory index operations.
		 *
		 * The index must be freed once it's no longer in use.
		 */
		[CCode(cname = "git_index_new")]
		public static Error create(out Index? index);
		/**
		 * Create a new bare Git index object as a memory representation of the Git
		 * index file in the index path, without a repository to back it.
		 *
		 * Since there is no ODB or working directory behind this index, any index
		 * methods which rely on these (e.g., {@link add}) will fail.
		 *
		 * If you need to access the index of an actual repository, use {@link Repository.get_index}.
		 *
		 * @param index where to put the new index
		 * @param index_path the path to the index file in disk
		 */
		public static Error open(out Index index, string index_path);

		/**
		 * Add or update an index entry from an in-memory struct
		 *
		 * A full copy (including the path string) of the given source will be
		 * inserted on the index.
		 *
		 * @param entry new entry object
		 */
		[CCode(cname = "git_index_add")]
		public Error add(IndexEntry entry);

		/**
		 * Add (append) an index entry from a file on disk
		 *
		 * A new entry will always be inserted into the index; if the index already
		 * contains an entry for such path, the old entry will ''not'' be replaced.
		 *
		 * The file path must be relative to the repository's working folder and
		 * must be readable.
		 *
		 * This method will fail in bare index instances.
		 *
		 * This forces the file to be added to the index, not looking at gitignore
		 * rules.
		 *
		 * If this file currently is the result of a merge conflict, this file will
		 * no longer be marked as conflicting. The data about the conflict will be
		 * moved to the "resolve undo" (REUC) section.
		 *
		 * @param path filename to add
		 */
		[CCode(cname = "git_index_add_bypath")]
		public Error add_path(string path);

		/**
		 * Clear the contents (all the entries) of an index object.
		 *
		 * This clears the index object in memory; changes must be manually written
		 * to disk for them to take effect.
		 */
		[CCode(cname = "git_index_clear")]
		public void clear();

		/**
		 * Add or update index entries to represent a conflict
		 *
		 * The entries are the entries from the tree included in the merge. Any
		 * entry may be null to indicate that that file was not present in the
		 * trees during the merge. For example, the ancestor entry may be null to
		 * indicate that a file was added in both branches and must be resolved.
		 *
		 * @param ancestor_entry the entry data for the ancestor of the conflict
		 * @param our_entry the entry data for our side of the merge conflict
		 * @param their_entry the entry data for their side of the merge conflict
		 */
		[CCode(cname = "git_index_conflict_add")]
		public Error conflict_add(IndexEntry? ancestor_entry, IndexEntry? our_entry, IndexEntry? their_entry);

		 /**
		 * Get the index entries that represent a conflict of a single file.
		 *
		 * The values of this entry can be modified (except the paths)
		 * and the changes will be written back to disk on the next
		 * write() call.
		 *
		 * @param ancestor Pointer to store the ancestor entry
		 * @param our Pointer to store the our entry
		 * @param their Pointer to store the their entry
		 * @param path path to search
		 */
		[CCode(cname = "git_index_conflict_get", instance_pos = 3.1)]
		public Error conflict_get(out unowned IndexEntry? ancestor, out unowned IndexEntry? our, out unowned IndexEntry? their, string path);

		/**
		 * Remove all conflicts in the index (entries with a stage greater than 0.)
		 */
		[CCode(cname = "git_index_conflict_cleanup")]
		public void conflict_cleanup();
		/**
		 * Removes the index entries that represent a conflict of a single file.
		 *
		 * @param path to search
		 */
		[CCode(cname = "git_index_conflict_remove")]
		public Error conflict_remove(string path);

		/**
		 * Find the first index of any entries which point to given path in the Git
		 * index.
		 *
		 * @param at_pos the address to which the position of the reuc entry is written (optional)
		 * @param path path to search
		 */
		[CCode(cname = "git_index_find", instance_pos = 1.1)]
		public Error find(out size_t at_pos, string path);

		/**
		 * Get a pointer to one of the entries in the index
		 *
		 * This entry can be modified, and the changes will be written back to disk
		 * on the next {@link write} call.
		 *
		 * @param n the position of the entry
		 * @return the entry; null if out of bounds
		 */
		[CCode(cname = "git_index_get_byindex")]
		public unowned IndexEntry? get(size_t n);

		/**
		 * Get a pointer to one of the entries in the index
		 *
		 * The values of this entry can be modified (except the path) and the
		 * changes will be written back to disk on the next {@link write} call.
		 *
		 * @param path path to search
		 * @param stage stage to search
		 */
		[CCode(cname = "git_index_get_bypath")]
		public unowned IndexEntry? get_by_path(string path, int stage);

		/**
		 * Remove all entries with equal path except last added
		 */
		[CCode(cname = "git_index_uniq")]
		public void make_unique();

		/**
		 * Update the contents of an existing index object in memory by reading
		 * from the hard disk.
		 */
		[CCode(cname = "git_index_read")]
		public Error read();

		/**
		 * Read a tree into the index file with stats
		 *
		 * The current index contents will be replaced by the specified tree.
		 *
		 * @param tree tree to read
		 */
		[CCode(cname = "git_index_read_tree")]
		public Error read_tree(Tree tree);

		/**
		 * Remove an entry from the index
		 */
		[CCode(cname = "git_index_remove")]
		public Error remove(string path, int stage);
		/**
		 * Remove all entries from the index under a given directory
		 *
		 * @param dir container directory path
		 * @param stage stage to search
		 */
		[CCode(cname = "git_index_remove_directory")]
		public Error remove_directory(string dir, int stage);

		/**
		 * Remove an index entry corresponding to a file on disk
		 *
		 * The file path must be relative to the repository's working folder.  It
		 * may exist.
		 *
		 * If this file currently is the result of a merge conflict, this file will
		 * no longer be marked as conflicting.  The data about the conflict will be
		 * moved to the "resolve undo" (REUC) section.
		 *
		 * @param path filename to remove
		 */
		[CCode(cname = "git_index_remove_bypath")]
		public Error remove_path(string path);

		/**
		 * Write an existing index object from memory back to disk using an atomic
		 * file lock.
		 */
		[CCode(cname = "git_index_write")]
		public Error write();

		/**
		 * Write the index as a tree
		 *
		 * This method will scan the index and write a representation of its
		 * current state back to disk; it recursively creates
		 * tree objects for each of the subtrees stored in the index, but only
		 * returns the OID of the root tree. This is the OID that can be used e.g.
		 * to create a commit.
		 *
		 * The index instance cannot be bare, and needs to be associated to an
		 * existing repository.
		 *
		 * The index must not contain any file in conflict.
		 */
		[CCode(cname = "git_index_write_tree", instance_pos = -1)]
		public Error write_tree(out object_id id);

		/**
		 * Write the index as a tree to the given repository
		 *
		 * This method will do the same as {@link write_tree}, but letting the user
		 * choose the repository where the tree will be written.
		 *
		 * The index must not contain any file in conflict.
		 *
		 * @param id Pointer where to store OID of the the written tree
		 * @param repo Repository where to write the tree
		 */
		[CCode(cname = "git_index_write_tree_to", instance_pos = 1.1)]
		public Error write_tree_to(out object_id id, Repository repo);

	}

	[CCode(cname = "git_indexer_stream", free_function = "git_indexer_stream_free", has_type_id = false)]
	public class IndexerStream {
		/**
		 * The packfile's hash
		 *
		 * A packfile's name is derived from the sorted hashing of all object
		 * names. This is only correct after the index has been finalized.
		 */
		public object_id? hash {
			[CCode(cname = "git_indexer_stream_hash")]
			get;
		}
		/**
		 * Create a new streaming indexer instance
		 *
		 * @param indexer_stream where to store the indexer instance
		 * @param path to the directory where the packfile should be stored
		 */
		[CCode(cname = "git_indexer_stream_new")]
		public static Error open(out IndexerStream indexer_stream, string path, TransferProgress transfer);

		/**
		 * Add data to the indexer
		 *
		 * @param data the data to add
		 * @param stats stat storage
		 */
		[CCode(cname = "git_indexer_stream_add")]
		public Error add([CCode(array_length_type = "size_t")] uint8[] data, transfer_progress stats);

		/**
		 * Finalize the pack and index
		 *
		 * Resolve any pending deltas and write out the index file
		 */
		[CCode(cname = "git_indexer_stream_finalize")]
		public Error finalize(transfer_progress stats);
	}

	/**
	 * Memory representation of a file entry in the index.
	 */
	[CCode(cname = "git_index_entry", has_type_id = false)]
	[Compact]
	public class IndexEntry {
		public Attributes flags;
		public index_time ctime;
		public index_time mtime;
		public int64 file_size;
		[CCode(cname = "oid")]
		public object_id id;
		public string path;
		public uint16 flags_extended;
		public uint dev;
		public uint gid;
		public uint ino;
		public uint mode;
		public uint uid;

		/**
		 * The stage number from a git index entry
		 */
		public int stage {
			[CCode(cname = "git_index_entry_stage")]
			get;
		}
	}
	/**
	 * A note attached to an object
	 */
	[CCode(cname = "git_note", free_function = "git_note_free", has_type_id = false)]
	[Compact]
	public class Note {
		/**
		 * The message for this note
		 */
		public string message {
			[CCode(cname = "git_note_message")]
			get;
		}

		/**
		 * The note object OID
		 */
		public object_id? id {
			[CCode(cname = "git_note_oid")]
			get;
		}
	}
	[CCode(cname = "git_note_iterator ", free_function = "git_note_iterator_free", has_type_id = false)]
	[Compact]
	public class NoteIterator {
		/**
		 * Returns the current item and advance the iterator internally to the next
		 * value.
		 */
		[CCode(cname = "git_note_next", instance_pos = -1)]
		public Error next(out object_id note_id, out object_id annotated_id);
	}
	/**
	 * Representation of a generic object in a repository
	 */
	[CCode(cname = "git_object", free_function = "git_object_free", has_type_id = false)]
	[Compact]
	public class Object {
		/**
		 * The id (SHA1) of a repository object
		 */
		public object_id? id {
			[CCode(cname = "git_object_id")]
			get;
		}

		/**
		 * The object type of an object
		 */
		public ObjectType type {
			[CCode(cname = "git_object_type")]
			get;
		}

		/**
		 * The repository that owns this object
		 */
		public Repository repository {
			[CCode(cname = "git_object_owner")]
			get;
		}
		/**
		 * Recursively peel an object until an object of the specified type is met
		 *
		 * @param target_type The type of the requested object
		 */
		[CCode(cname = "git_object_peel", instance_pos = 1.1)]
		public Error peel(out Object? peeled, ObjectType target_type);
	}

	[Compact]
	[CCode(cname = "git_packbuilder", free_function = "git_packbuilder_free", has_type_id = false)]
	public class PackBuilder {

		/**
		 * The total number of objects the packbuilder will write out
		 */
		public uint32 count {
			[CCode(cname = "packbuilder_object_count")]
			get;
		}
		/**
		 * The number of objects the packbuilder has already written out
		 */
		public uint32 written {
			[CCode(cname = "git_packbuilder_written")]
			get;
		}

		/**
		 * Set number of threads to spawn
		 *
		 * By default, libgit2 won't spawn any threads at all; when set to 0,
		 * libgit2 will autodetect the number of CPUs.
		 *
		 * @param n Number of threads to spawn
		 * @return number of actual threads to be used
		 */
		[CCode(cname = "git_packbuilder_set_threads")]
		public uint set_threads(uint n);

		/**
		 * Insert a single object
		 *
		 * For an optimal pack it's mandatory to insert objects in recency order,
		 * commits followed by trees and blobs.
		 *
		 * @param id The oid of the commit
		 * @param name The name
		 */
		[CCode(cname = "git_packbuilder_insert")]
		public Error insert(object_id id, string? name);
		/**
		 * Insert a root tree object
		 *
		 * This will add the tree as well as all referenced trees and blobs.
		 *
		 * @param id The oid of the root tree
		 */
		[CCode(cname = "git_packbuilder_insert_tree")]
		public Error insert_tree(object_id id);

		/**
		 * Write the new pack and the corresponding index to path
		 *
		 * @param path Directory to store the new pack and index
		 */
		[CCode(cname = "git_packbuilder_write")]
		public Error write(string path);

		/**
		 * Create the new pack and pass each object to the callback
		 */
		[CCode(cname = "git_packbuilder_foreach")]
		public Error for_each(PackBuilderForEach pack_builder_for_each);
	}
	/**
	 * The list of parents of a commit
	 */
	[Compact]
	[CCode(cname = "git_commit", has_type_id = false)]
	public class Parents {
		/**
		 * Get the number of parents of this commit
		 */
		public uint size {
			[CCode(cname = "git_commit_parentcount")]
			get;
		}

		/**
		 * Get the id of a specified parent for a commit.
		 *
		 * This is different from {@link Parents.lookup}, which will attempt
		 * to load the parent commit from the ODB.
		 *
		 * @param n the position of the parent
		 * @return the id of the parent, null on error.
		 */
		[CCode(cname = "git_commit_parent_id")]
		public unowned object_id? get(uint n);

		/**
		 * Get the specified parent of the commit.
		 *
		 * @param parent where to store the parent commit
		 * @param n the position of the parent
		 */
		[CCode(cname = "git_commit_parent", instance_pos = 1.2)]
		public Error lookup(out Commit parent, uint n);
	}
	[CCode(cname = "git_diff_patch ", free_function = "git_diff_patch_free", has_type_id = false)]
	[Compact]
	public class Patch {
		/**
		 * The delta associated with a patch
		 */
		public diff_delta? delta {
			[CCode(cname = "git_diff_patch_delta")]
			get;
		}
		/**
		 * The number of hunks in a patch
		 */
		public size_t num_hunks {
			[CCode(cname = "git_diff_patch_num_hunks")]
			get;
		}
		/**
		 * Get the information about a hunk in a patch
		 *
		 * Given a patch and a hunk index into the patch, this returns detailed
		 * information about that hunk. Any of the output pointers can be passed
		 * as NULL if you don't care about that particular piece of information.
		 *
		 * @param range Range of the hunk
		 * @param header Header string for hunk. Unlike the content for each line,
		 * this will be NUL-terminated
		 * @param lines_in_hunk Count of total lines in this hunk
		 * @param hunk_idx Input index of hunk to get information about
		 */
		[CCode(cname = "git_diff_patch_get_hunk", instance_pos = 3.1)]
		public Error get_hunk(out unowned diff_range? range, [CCode(array_length_type = "size_t")] out unowned uint8[]? header, out size_t lines_in_hunk, size_t hunk_idx);
		/**
		 * Get data about a line in a hunk of a patch.
		 *
		 * Given a patch, a hunk index, and a line index in the hunk, this will
		 * return a lot of details about that line. If you pass a hunk index
		 * larger than the number of hunks or a line index larger than the number
		 * of lines in the hunk, this will return -1.
		 *
		 * @param old_lineno Line number in old file or -1 if line is added
		 * @param new_lineno Line number in new file or -1 if line is deleted
		 * @param hunk_idx The index of the hunk
		 * @param line_of_hunk The index of the line in the hunk
		 */
		[CCode(cname = "git_diff_patch_get_line_in_hunk", instance_pos = 4.1)]
		public Error get_line_in_hunk(out DiffLineType line_origin, [CCode(array_length_type = "size_t")] out unowned uint8[]? content, out int old_lineno, out int new_lineno, size_t hunk_idx, size_t line_of_hunk);
		/**
		 * Get line counts of each type in a patch.
		 *
		 * This helps imitate a '''diff --numstat''' type of output.  For that
		 * purpose, you only need the total additions and total_deletions values,
		 * but we include the total context line count in case you want the total
		 * number of lines of diff output that will be generated.
		 *
		 * @param total_context Count of context lines in output.
		 * @param total_additions Count of addition lines in output.
		 * @param total_deletions Count of deletion lines in output.
		 * @return Number of lines in hunk or -1 if invalid hunk index
		 */
		[CCode(cname = "git_diff_patch_line_stats", instance_pos = -1)]
		public int get_line_stats(out size_t total_context, out size_t total_additions, out size_t total_deletions);

		/**
		 * Get the number of lines in a hunk.
		 *
		 * @param hunk_idx Index of the hunk
		 * @return Number of lines in hunk or -1 if invalid hunk index
		 */
		[CCode(cname = "git_diff_patch_num_lines_in_hunk")]
		public int num_lines_in_hunk(size_t hunk_idx);

		/**
		 * Serialize the patch to text via callback.
		 */
		[CCode(cname = "git_diff_patch_print")]
		public Error patch_print(DiffOutput print);

		/**
		 * Get the content of a patch as a single diff text.
		 */
		[CCode(cname = "git_diff_patch_to_str", instance_pos = -1)]
		public Error to_str(out string str);

		public string? to_string() {
			string? str;
			return to_str(out str) == Error.OK ? str : null;
		}
	}
	[Compact]
	[CCode(cname = "git_push", free_function = "git_push_free", has_type_id = false)]
	public class Push {
		/**
		 * Check if remote side successfully unpacked
		 */
		public bool unpack_ok {
			[CCode(cname = "git_push_unpack_ok")]
			get;
		}

		/**
		 * Add a refspec to be pushed
		 */
		[CCode(cname = "git_push_add_refspec")]
		public Error add_refspec(string refspec);

		/**
		 * Actually push all given refspecs
		 *
		 * To check if the push was successful (i.e. all remote references have
		 * been updated as requested), you need to call both {@link unpack_ok} and
		 * {@link for_each}. The remote repository might have refused to update
		 * some or all of the references.
		 */
		[CCode(cname = "git_push_finish")]
		public Error finish();
		/**
		 * Iterate over each status.
		 *
		 * For each of the updated references, we receive a status report in the
		 * form of '''ok refs/heads/master''' or '''ng refs/heads/master ///msg///'''.
		 * If the message is not null, this means the reference has not been
		 * updated for the given reason.
		 *
		 */
		[CCode(cname = "git_push_status_foreach")]
		public Error for_each(PushForEach push_for_each);
		/**
		 * Set options on a push object
		 *
		 * @param opts The options to set on the push object
		 */
		[CCode(cname = "git_push_set_options")]
		public Error set_options(push_options opts);
		/**
		 * Update remote tips after a push
		 */
		[CCode(cname = "git_push_update_tips")]
		public Error update_tips();
	}
	[CCode(cname = "git_refdb", has_type_id = false, free_function = "git_refdb_free")]
	public class RefDb {
		/**
		 * Create a new reference.  Either an oid or a symbolic target must be
		 * specified.
		 *
		 * @param name the reference name
		 * @param id the object id for a direct reference
		 * @param symbolic the target for a symbolic reference
		 */
		[CCode(cname = "git_reference__alloc")]
		public Reference? alloc(string name, object_id id, string symbolic);

		/**
		* Suggests that the given refdb compress or optimize its references.
		*
		* This mechanism is implementation specific.  For on-disk reference
		* databases, for example, this may pack all loose references.
		*/
		[CCode(cname = "git_refdb_compress")]
		public Error compress();

		/**
		 * Sets the custom backend to an existing reference DB
		 */
		 [CCode(cname = "git_refdb_set_backend")]
		 public Error set_backend(owned refdb_backend backend);
	}
	/**
	 * In-memory representation of a reference.
	 */
	[CCode(cname = "git_reference", free_function = "git_reference_free", has_type_id = false)]
	[Compact]
	public class Reference {
		/**
		 * Check if a reflog exists for the specified reference.
		 */
		public bool has_log {
		[CCode(cname = "git_reference_has_log")]
			get;
		}
		/**
		 * Check if a reference is a local branch.
		 */
		public bool is_branch {
			[CCode(cname = "git_reference_is_branch")]
			get;
		}

		/**
		 * Determine if the current local branch is pointed at by HEAD.
		 */
		public bool is_head {
			[CCode(cname = "0 != git_branch_is_head")]
			get;
		}

		/**
		 * If a reference is a remote tracking branch
		 */
		public bool is_remote {
			[CCode(cname = "git_reference_is_remote")]
			get;
		}

		/**
		 * The full name of a reference
		 */
		public string name {
			[CCode(cname = "git_reference_name")]
			get;
		}

		/**
		 * The repository where a reference resides
		 */
		public Repository repository {
			[CCode(cname = "git_reference_owner")]
			get;
		}

		/**
		 * The full name to the reference pointed by this reference
		 *
		 * Only available if the reference is symbolic
		 */
		public string? symbolic_target {
			[CCode(cname = "git_reference_symbolic_target")]
			get;
		}

		/**
		 * The id pointed to by a reference.
		 *
		 * Only available if the reference is direct (i.e., not symbolic)
		 */
		public object_id? target {
			[CCode(cname = "git_reference_target")]
			get;
		}

		/**
		 * The type of a reference
		 *
		 * Either direct, {@link ReferenceType.ID}, or symbolic, {@link ReferenceType.SYMBOLIC}
		 */
		public ReferenceType type {
			[CCode(cname = "git_reference_type")]
			get;
		}
		/**
		 * Ensure the reference name is well-formed.
		 *
		 * Valid reference names must follow one of two patterns:
		 *
		 * 1. Top-level names must contain only capital letters and underscores,
		 * and must begin and end with a letter. (e.g. "HEAD", "ORIG_HEAD").
		 * 2. Names prefixed with "refs/" can be almost anything. You must avoid
		 * the characters '~', '^', ':', '\\', '?', '[', and '*', and the
		 * sequences ".." and "@{" which have special meaning to revparse.
		 */
		[CCode(cname = "git_reference_is_valid_name")]
		public static bool is_valid_name(string refname);

		/**
		 * Delete an existing branch reference.
		 */
		[CCode(cname = "git_branch_delete")]
		public static Error delete_branch(owned Reference reference);
		/**
		 * Normalize the reference name by removing any leading slash (/)
		 * characters and collapsing runs of adjacent slashes between name
		 * components into a single slash.
		 *
		 * Once normalized, if the reference name is valid, it will be returned in
		 * the user allocated buffer.

		 * @param buffer The buffer where the normalized name will be stored.
		 * @param name name to be checked.
		 * @param flags Flags to determine the options to be applied while checking
		 * the validatity of the name.
		 */
		[CCode(cname = "git_reference_normalize_name")]
		public static Error normalize_name([CCode(array_length_type = "size_t")] uint8[] buffer, string name, ReferenceFormat flags);

		/**
		 * Compare two references.
		 *
		 * @return 0 if the same, else a stable but meaningless ordering.
		 */
		[CCode(cname = "git_reference_cmp")]
		public int compare(Reference other);

		/**
		 * Delete an existing reference
		 *
		 * This method works for both direct and symbolic references.
		 *
		 * The reference will be immediately removed on disk.
		 */
		[CCode(cname = "git_reference_delete")]
		public void @delete();

		/**
		 * Delete the reflog for the given reference
		 */
		[CCode(cname = "git_reflog_delete")]
		public Error delete_reflog();

		/**
		 * Return the name of the given local or remote branch.
		 *
		 * The name of the branch matches the definition of the name for
		 * {@link Repository.lookup_branch}. That is, if the returned name is
		 * looked up then the reference is returned that was given to this
		 * function.
		 *
		 * @param name where the pointer of branch name is stored;
		 * this is valid as long as the ref is not freed.
		 */
		[CCode(cname = "git_branch_name", instance_pos = -1)]
		public Error get_branch_name(out unowned string name);

		/**
		 * Read the reflog for the given reference
		 *
		 * @param reflog where to put the reflog
		 */
		[CCode(cname = "git_reflog_read", instance_pos = -1)]
		public Error get_reflog(out ReferenceLog? reflog);
		/**
		 * Return the reference supporting the remote tracking branch, given a
		 * reference branch.
		 *
		 * The input reference has to be located in the '''refs/heads''' namespace.
		 *
		 */
		[CCode(cname = "git_reference_remote_tracking_from_branch", instance_pos = -1)]
		public Error get_remote_tracking_from_branch(out Reference tracking_ref);
		/**
		 * Return the reference supporting the remote tracking branch, given a
		 * local branch reference.
		 */
		[CCode(cname = "git_branch_tracking", instance_pos = -1)]
		public Error get_tracking(out Reference? tracking);

		/**
		 * Move/rename an existing branch reference.
		 *
		 * @param new_branch_name Target name of the branch once the move
		 * is performed; this name is validated for consistency.
		 *
		 * @param force Overwrite existing branch.
		 */
		[CCode(cname = "git_branch_move", instance_pos = 1.1)]
		public Error move_branch(out Reference? moved, string new_branch_name, bool force);

		/**
		 * Recursively peel an reference until an object of the specified type is
		 * met.
		 *
		 * If you pass {@link ObjectType.ANY} as the target type, then the object
		 * will be peeled until a non-tag object is met.
		 *
		 * @param target_type The type of the requested object
		 */
		[CCode(cname = "git_reference_peel", instance_pos = 1.1)]
		public Error peel(out Object? peeled, ObjectType target_type);

		/**
		 * Rename an existing reference
		 *
		 * This method works for both direct and symbolic references.
		 * The new name will be checked for validity and may be
		 * modified into a normalized form.
		 *
		 * The refernece will be immediately renamed in-memory
		 * and on disk.
		 *
		 * ''IMPORTANT:'' The user needs to write a proper reflog entry if the
		 * reflog is enabled for the repository. We only rename the reflog if it
		 * exists.
		 *
		 */
		[CCode(cname = "git_reference_rename", instance_pos = 1.1)]
		public Error rename(out Reference? renamed_reference, string new_name, bool force);

		/**
		 * Resolve a symbolic reference
		 *
		 * Thie method iteratively peels a symbolic reference
		 * until it resolves to a direct reference to an id.
		 *
		 * If a direct reference is passed as an argument,
		 * that reference is returned immediately
		 *
		 * @param resolved the peeled reference
		 */
		[CCode(cname = "git_reference_resolve", instance_pos = -1)]
		public Error resolve(out Reference resolved);

		/**
		 * Create a new reference with the same name as the given reference but a
		 * different symbolic target.
		 *
		 * The reference must be a symbolic reference, otherwise this will fail.
		 *
		 * The new reference will be written to disk, overwriting the given
		 * reference.
		 *
		 * @param id the new target id for the reference
		 */
		[CCode(cname = "git_reference_set_oid", instance_pos = 1.1)]
		public Error set_target(out Reference? retargeted, object_id id);

		/**
		 * Set the symbolic target of a reference.
		 *
		 * The reference must be a symbolic reference, otherwise this method will
		 * fail.
		 *
		 * The reference will be automatically updated in memory and on disk.
		 *
		 * @param target The new target for the reference
		 */
		[CCode(cname = "git_reference_symbolic_set_target")]
		public Error set_symbolic_target(string target);
	}

	/**
	 * Representation of a reference log
	 */
	[CCode(cname = "git_reflog", free_function = "git_reflog_free", has_type_id = false)]
	[Compact]
	public class ReferenceLog {
		/**
		 * The number of log entries in a reflog
		 */
		public size_t size {
			[CCode(cname = "git_reflog_entrycount")]
			get;
		}

		/**
		 * Add a new entry to the reflog.
		 *
		 * If there is no reflog file for the given reference yet, it will be
		 * created.
		 *
		 * @param id the id the reference is now pointing to
		 * @param committer the signature of the committer
		 * @param msg the reflog message
		 */
		[CCode(cname = "git_reflog_append")]
		public Error append(out object_id id, Signature committer, string? msg = null);

		/**
		 * Remove an entry from the reflog by its index
		 *
		 * To ensure there's no gap in the log history, when deleting an entry,
		 * member old_oid of the previous entry (if any) will be updated with the
		 * value of memeber new_oid of next entry.
		 *
		 * @param idx the position of the entry to remove.
		 *
		 * @param rewrite_previous_entry true to rewrite the history; 0 otherwise.
		 *
		 */
		[CCode(cname = "git_reflog_drop")]
		public Error drop(size_t idx, bool rewrite_previous_entry);

		/**
		 * Lookup an entry by its index
		 *
		 * @param idx the position to lookup
		 * @return the entry; null if not found
		 */
		[CCode(cname = "git_reflog_entry_byindex")]
		public unowned ReferenceLogEntry? get(size_t idx);

		/**
		 * Rename the reflog for the given reference
		 *
		 * @param new_name the new name of the reference
		 */
		[CCode(cname = "git_reflog_rename")]
		public Error rename(string new_name);
		/**
		 * Write an existing in-memory reflog object back to disk using an atomic
		 * file lock.
		 *
		 * If there is no reflog file for the given reference yet, it will be
		 * created.
		 */
		[CCode(cname = "git_reflog_write")]
		public Error write();
	}

	/**
	 * Representation of a reference log entry
	 */
	[CCode(cname = "git_reflog_entry", has_type_id = false)]
	[Compact]
	public class ReferenceLogEntry {

		/**
		 * The committer of this entry
		 */
		public Signature commiter {
			[CCode(cname = "git_reflog_entry_committer")]
			get;
		}

		/**
		 * The log message
		 */
		public string message {
			[CCode(cname = "git_reflog_entry_msg")]
			get;
		}

		/**
		 * The new id at this time
		 */
		public object_id? new_id {
			[CCode(cname = "git_reflog_entry_id_new")]
			get;
		}

		/**
		 * The old id
		 */
		public object_id? old_id {
			[CCode(cname = "git_reflog_entry_id_old")]
			get;
		}
	}

	/**
	 * Reference to a remote repository
	 */
	[CCode(cname = "git_remote", free_function = "git_remote_free", has_type_id = false)]
	[Compact]
	public class Remote {
		[CCode(cname = "git_remote_rename_problem_cb")]
		public delegate bool RenameProblem(string problematic_refspec);
		/**
		 * The tag auto-follow setting
		 */
		public AutoTag autotag {
			[CCode(cname = "git_remote_autotag")]
			get;
			[CCode(cname = "git_remote_set_autotag")]
			set;
		}

		/**
		 * Choose whether to check the server's certificate (applies to HTTPS only)
		 */
		public bool check_cert {
			[CCode(cname = "git_remote_check_cert")]
			set;
		}

		/**
		 * Whether the remote is connected
		 *
		 * Whether the remote's underlying transport is connected to the remote
		 * host.
		 */
		public bool is_connected {
			[CCode(cname = "git_remote_connected")]
			get;
		}

		/**
		 * The fetch refspec, if it exists
		 */
		public ref_spec? fetch_spec {
			[CCode(cname = "git_remote_fetchspec")]
			get;
			[CCode(cname = "git_remote_set_fetchspec")]
			set;
		}

		/**
		 * The remote's name
		 */
		public string? name {
			[CCode(cname = "git_remote_name")]
			get;
		}

		/**
		 * The push refspec, if it existsc
		 */
		public ref_spec? push_spec {
			[CCode(cname = "git_remote_pushspec")]
			get;
			[CCode(cname = "git_remote_set_pushspec")]
			set;
		}

		/**
		 * The statistics structure that is filled in by the fetch operation.
		 */
		public transfer_progress stats {
			[CCode(cname = "git_remote_stats")]
			get;
		}

		/**
		 * Update FETCH_HEAD on ever fetch.
		 */
		public bool update_fetchhead {
			[CCode(cname = "git_remote_update_fetchhead")]
			get;
			[CCode(cname = "git_remote_set_update_fetchhead")]
			set;
		}
		/**
		 * The remote's URL
		 */
		public string url {
			[CCode(cname = "git_remote_url")]
			get;
		}

		/**
		 * Ensure the remote name is well-formed.
		 *
		 * @param remote_name name to be checked.
		 */
		[CCode(cname = "git_remote_is_valid_name")]
		public static bool is_valid_name(string remote_name);

		/**
		 * Return whether a string is a valid remote URL
		 *
		 * @param url the url to check
		 */
		[CCode(cname = "git_remote_valid_url")]
		public static bool is_valid_url(string url);

		/**
		 * Return whether the passed URL is supported by this version of the library.
		 *
		 * @param url the url to check
		*/
		[CCode(cname = "git_remote_supported_url")]
		public static bool is_supported_url(string url);
		/**
		 * Create a new push object
		 */
		[CCode(cname = "git_push_new", instance_pos = -1)]
		public Error create_push(out Push? push);

		/**
		 * Open a connection to a remote
		 *
		 * The transport is selected based on the URL. The direction argument is
		 * due to a limitation of the git protocol (over TCP or SSH) which starts
		 * up a specific binary which can only do the one or the other.
		 *
		 * @param direction whether you want to receive or send data
		 */
		[CCode(cname = "git_remote_connect")]
		public Error connect(Direction direction);

		/**
		 * Download the packfile
		 *
		 * Negotiate what objects should be downloaded and download the packfile
		 * with those objects.
		 */
		[CCode(cname = "git_remote_download")]
		public Error download(Progress progress);

		/**
		 * Disconnect from the remote
		 *
		 * Close the connection to the remote and free the underlying transport.
		 */
		[CCode(cname = "git_remote_disconnect")]
		public void disconnect();

		/**
		 * Get a list of refs at the remote
		 *
		 * The remote (or more exactly its transport) must be connected.
		 */
		[CCode(cname = "git_remote_ls", instance_pos = -1)]
		public Error list(Head headcb);

		/**
		 * Give the remote a new name
		 *
		 * All remote-tracking branches and configuration settings for the remote
		 * are updated.
		 *
		 * The new name will be checked for validity.
		 *
		 * A temporary in-memory remote cannot be given a name with this method.
		 *
		 * @param new_name the new name the remote should bear
		 * @param rename_problem Optional callback to notify the consumer of fetch refspecs
		 * that haven't been automatically updated and need potential manual tweaking.
		 * @see Repository.create_tag
		 */
		[CCode(cname = "git_remote_rename")]
		public Error rename(string new_name, RenameProblem? rename_problem = null);
		/**
		 * Save a remote to its repository's configuration
		 *
		 * One can't save a in-memory remote. Doing so will result in a
		 * {@link Error.INVALIDSPEC} being returned.
		 */
		[CCode(cname = "git_remote_save")]
		public Error save();
		/**
		 * Set the callbacks for a remote
		 */
		[CCode(cname = "git_remote_set_callbacks", simple_generics = true)]
		public Error set_callbacks<T>(remote_callbacks<T> callbacks);

		/**
		 * Sets the owning repository for the remote. This is only allowed on
		 * dangling remotes.
		 */
		[CCode(cname = "git_remote_set_repository")]
		public Error set_repository(Repository repo);

		/**
		 * Sets a credentials acquisition callback for this remote.
		 *
		 * If the remote is not available for anonymous access, then you must set
		 * this callback in order to provide credentials to the transport at the
		 * time of authentication failure so that retry can be performed.
		 */
		[CCode(cname = "git_remote_set_cred_acquire_cb")]
		public void set_cred_acquire(CredAcquire? cred_acquire);

		/**
		 * Sets a custom transport for the remote. The caller can use this function
		 * to bypass the automatic discovery of a transport by URL scheme (i.e.,
		 * http, https, git) and supply their own transport to be used
		 * instead. After providing the transport to a remote using this function,
		 * the transport object belongs exclusively to that remote, and the remote will
		 * free it when it is freed with git_remote_free.
		 *
		 * @param transport the transport object for the remote to use
		 */
		[CCode(cname = "git_remote_set_transport")]
		public Error set_transport(transport transport);

		/**
		 * Cancel the operation
		 *
		 * At certain points in its operation, the network code checks whether the
		 * operation has been cancelled and if so stops the operation.
		 */
		[CCode(cname = "git_remote_stop")]
		public void stop();

		/**
		 * Update the tips to the new state
		 *
		 * Make sure that you only call this once you've successfully indexed or
		 * expanded the packfile.
		 */
		[CCode(cname = "git_remote_update_tips")]
		public Error update_tips(Update update);
	}

	/**
	 * Representation of an existing git repository,
	 * including all its object contents
	 */
	[CCode(cname = "git_repository", free_function = "git_repository_free", has_type_id = false)]
	[Compact]
	public class Repository {
		public Attr attributes {
			[CCode(cname = "")]
			get;
		}
		/**
		 * Check if a repository is bare
		 */
		public bool is_bare {
			[CCode(cname = "git_repository_is_bare")]
			get;
		}
		/**
		 * Check if a repository's HEAD is detached
		 *
		 * A repository's HEAD is detached when it points directly to a commit
		 * instead of a branch.
		 */
		public bool is_head_detached {
			[CCode(cname = "git_repository_head_detached")]
			get;
		}

		/**
		 * Check if the current branch is an orphan
		 *
		 * An orphan branch is one named from HEAD but which doesn't exist in
		 * the refs namespace, because it doesn't have any commit to point to.
		 */
		public bool is_head_orphan {
			[CCode(cname = "git_repository_head_orphan")]
			get;
		}

		/**
		 * Check if a repository is empty
		 *
		 * An empty repository has just been initialized and contains no commits.
		 */
		public bool is_empty {
			[CCode(cname = "git_repository_is_empty")]
			get;
		}

		/**
		 * The path to the repository.
		 */
		public string? path {
			[CCode(cname = "git_repository_path")]
			get;
		}
		/**
		 * Determines the status of a git repository (i.e., whether an operation
		 * such as a merge or cherry-pick is in progress).
		 */
		public State state {
			[CCode(cname = "git_repository_state")]
			get;
		}

		/**
		 * The working directory for this repository
		 *
		 * If the repository is bare, this is null.
		 *
		 * If this repository is bare, setting its working directory will turn it
		 * into a normal repository, capable of performing all the common workdir
		 * operations (checkout, status, index manipulation, etc).
		 */
		public string? workdir {
			[CCode(cname = "git_repository_workdir")]
			get;
			set {
				set_workdir((!)value, true);
			}
		}

		/**
		 * Clone a remote repository, and checkout the branch pointed to by the remote
		 * HEAD.
		 *
		 * @param origin_url repository to clone from
		 * @param dest_path local directory to clone to
		 * @param clone_opts configuration options for the clone.
		 */
		[CCode(cname = "git_clone")]
		public static Error clone(out Repository? repo, string origin_url, string dest_path, clone_opts? clone_opts = null);

		/**
		 * Look for a git repository and copy its path in the given buffer. The lookup start
		 * from base_path and walk across parent directories if nothing has been found. The
		 * lookup ends when the first repository is found, or when reaching a directory
		 * referenced in ceiling_dirs or when the filesystem changes (in case across_fs
		 * is true).
		 *
		 * The method will automatically detect if the repository is bare (if there is
		 * a repository).
		 *
		 * @param repository_path The buffer which will contain the found path.
		 *
		 * @param start_path The base path where the lookup starts.
		 *
		 * @param across_fs If true, then the lookup will not stop when a filesystem device change
		 * is detected while exploring parent directories.
		 *
		 * @param ceiling_dirs A {@link PATH_LIST_SEPARATOR} separated list of absolute symbolic link free paths. The lookup will stop when any of this paths is reached. Note that the lookup always performs on //start_path// no matter start_path appears in //ceiling_dirs//. //ceiling_dirs// might be null, which is equivalent to an empty string.
		 */
		public static Error discover([CCode(array_length_type = "size_t")] char[] repository_path, string start_path, bool across_fs = true, string? ceiling_dirs = null);

		/**
		 * Creates a new Git repository in the given folder.
		 *
		 * @param repo the repo which will be created or reinitialized
		 * @param path the path to the repository
		 * @param is_bare if true, a git repository without a working directory is created at the pointed path. If false, provided path will be considered as the working directory into which the //.git// directory will be created.
		 */
		[CCode(cname = "git_repository_init")]
		public static Error init(out Repository repo, string path, bool is_bare);
		/**
		 * Create a new Git repository in the given folder with extended controls.
		 *
		 * This will initialize a new git repository (creating the path if
		 * requested by flags) and working directory as needed. It will
		 * auto-detect the case sensitivity of the file system and if the file
		 * system supports file mode bits correctly.
		 *
		 * @param repo_path The path to the repository.
		 * @param opts Pointer to git_repository_init_options struct.
		 */
		[CCode(cname = "git_repository_init_ext")]
		public static Error init_ext(out Repository? repo, string repo_path, init_options opts);

		/**
		 * Open a git repository.
		 *
		 * The path argument must point to an existing git repository
		 * folder. The repository can be normal (having a //.git// directory)
		 * or bare (having objects, index, and HEAD directly).
		 * The method will automatically detect if path is a normal
		 * or bare repository or fail is path is neither.
		 *
		 * @param repository the repo which will be opened
		 * @param path the path to the repository
		 */
		[CCode(cname = "git_repository_open")]
		public static Error open(out Repository? repository, string path);

		/**
		 * Find and open a repository with extended controls.
		 */
		[CCode(cname = "git_repository_open_ext")]
		public static Error open_ext(out Repository? repository, string start_path, OpenFlags flags, string ceiling_dirs);
		/**
		 * Add ignore rules for a repository.
		 *
		 * Excludesfile rules (i.e. .gitignore rules) are generally read from
		 * .gitignore files in the repository tree or from a shared system file
		 * only if a "core.excludesfile" config value is set. The library also
		 * keeps a set of per-repository internal ignores that can be configured
		 * in-memory and will not persist. This function allows you to add to
		 * that internal rules list.
		 *
		 * @param rules Text of rules, a la the contents of a .gitignore file. It
		 * is okay to have multiple rules in the text; if so, each rule should be
		 * terminated with a newline.
		 */
		[CCode(cname = "git_ignore_add_rule")]
		public Error add_ignore(string rules);
		/**
		 * Set up a new git submodule for checkout.
		 *
		 * This does '''git submodule add''' up to the fetch and checkout of the
		 * submodule contents. It preps a new submodule, creates an entry in
		 * .gitmodules and creates an empty initialized repository either at the
		 * given path in the working directory or in .git/modules with a gitlink
		 * from the working directory to the new repo.
		 *
		 * To fully emulate '''git submodule add''' call this function, then open
		 * the submodule repo and perform the clone step as needed. Lastly, call
		 * {@link Submodule.add_finalize} to wrap up adding the new submodule and
		 * .gitmodules to the index to be ready to commit.
		 *
		 * @param submodule The newly created submodule ready to open for clone
		 * @param url URL for the submodules remote
		 * @param path Path at which the submodule should be created
		 * @param use_gitlink Should workdir contain a gitlink to the repo in
		 * .git/modules vs. repo directly in workdir.
		 */
		[CCode(cname = "git_submodule_add_setup", instance_pos = 1.1)]
		public Error add_submodule_setup(out Submodule? submodule, string url, string path, bool use_gitlink);

		/**
		 * Remove all the metadata associated with an ongoing git merge, including
		 * MERGE_HEAD, MERGE_MSG, etc.
		 */
		[CCode(cname = "git_repository_merge_cleanup")]
		public Error cleanup_merge();

		/**
		 * Clear ignore rules that were explicitly added.
		 *
		 * Resets to the default internal ignore rules. This will not turn off
		 * rules in .gitignore files that actually exist in the filesystem.
		 *
		 * The default internal ignores ignore '''.''', '''..''' and '''.git''' entries.
		 */
		public Error clear_internal_ignores();

		/**
		 * Updates files in the index and the working tree to match the commit pointed to by HEAD.
		 *
		 * @param opts specifies checkout options
		 */
		[CCode(cname = "git_checkout_head")]
		public Error checkout_head(checkout_opts? opts = null);
		/**
		 * Updates files in the working tree to match the content of the index.
		 *
		 * @param opts specifies checkout options
		 * @param index index to be checked out (or null to use repository index)
		 */
		[CCode(cname = "git_checkout_index")]
		public Error checkout_index(Index? index = null, checkout_opts? opts = null);
		/**
		 * Updates files in the index and working tree to match the content of a
		 * tree.
		 *
		 * @param treeish a commit, tag or tree which content will be used to
		 * update the working directory
		 * @param opts specifies checkout options
		 */
		[CCode(cname = "git_checkout_tree")]
		public Error checkout_tree(Object treeish, checkout_opts? opts = null);
		/**
		 * Count the number of unique commits between two commit objects
		 *
		 * There is no need for branches containing the commits to have any
		 * upstream relationship, but it helps to think of one as a branch and the
		 * other as its upstream, the ahead and behind values will be what git
		 * would report for the branches.
		 *
		 * @param ahead number of unique commits in upstream
		 * @param behind number of unique commits in local
		 * @param local one of the commits
		 * @param upstream the other commit
		 */
		[CCode(cname = "git_graph_ahead_behind", instance_pos = 2.1)]
		public Error count_ahead_behind(out size_t ahead, out size_t behind, object_id local, object_id upstream);
		/**
		 * Write an in-memory buffer to the ODB as a blob
		 *
		 * @param id return the id of the written blob
		 * @param buffer data to be written into the blob
		 */
		[CCode(cname = "git_blob_create_frombuffer", instance_pos = 1.2)]
		public Error create_blob_from_buffer(object_id id, [CCode(array_length_type = "size_t")] uint8[] buffer);
		/**
		 * Write a loose blob to the Object Database from a provider of chunks of
		 * data.
		 *
		 * @param id Return the id of the written blob
		 * @param hint_path will help to determine what git filters should be
		 * applied to the object before it can be placed to the object database.
		 */
		[CCode(cname = "git_blob_create_fromchunks", instance_pos = 1.2)]
		public Error create_blob_from_chunks(object_id id, string? hint_path, ChunkSource source);

		/**
		 * Read a file from the filesystem and write its content to the Object
		 * Database as a loose blob
		 *
		 * @param id return the id of the written blob
		 * @param path file from which the blob will be created
		 */
		[CCode(cname = "git_blob_create_fromdisk", instance_pos = 1.2)]
		public Error create_blob_from_disk(out object_id id, string path);

		/**
		 * Read a file from the working folder of a repository
		 * and write it to the object database as a loose blob
		 *
		 * This repository cannot be bare.
		 *
		 * @param id return the id of the written blob
		 * @param path file from which the blob will be created, relative to the repository's working dir
		 */
		[CCode(cname = "git_blob_create_fromworkdir", instance_pos = 1.2)]
		public Error create_blob_from_file(object_id id, string path);

		/**
		 * Create a new branch pointing at a target commit
		 *
		 * A new direct reference will be created pointing to this target commit.
		 * If forced and a reference already exists with the given name, it'll be
		 * replaced.
		 *
		 * @param branch_name Name for the branch; this name is
		 * validated for consistency. It should also not conflict with
		 * an already existing branch name.
		 *
		 * @param target Object to which this branch should point. This object must
		 * belong to the given repository and can either be a commit or a tag. When
		 * a tag is being passed, it should be dereferencable to a commit which oid
		 * will be used as the target of the branch.
		 *
		 * @param force Overwrite existing branch.
		 */
		[CCode(cname = "git_branch_create", instance_pos = 1.2)]
		public Error create_branch(out Reference? branch, string branch_name, Commit target, bool force = false);

		/**
		 * Create a new commit in the repository using {@link Object}
		 * instances as parameters.
		 *
		 * The message will not be cleaned up.
		 *
		 * @param id the id of the newly created commit
		 *
		 * @param update_ref If not null, name of the reference that will be updated to point to this commit. If the reference is not direct, it will be resolved to a direct reference. Use //"HEAD"// to update the HEAD of the current branch and make it point to this commit.
		 * @param author Signature representing the author and the author time of this commit
		 * @param committer Signature representing the committer and the commit time of this commit
		 * @param message_encoding The encoding for the message in the commit, represented with a standard encoding name (e.g., //"UTF-8"//). If null, no encoding header is written and UTF-8 is assumed.
		 * @param message Full message for this commit
		 * @param tree The tree that will be used as the tree for the commit. This tree object must also be owned by this repository.
		 * @param parents The commits that will be used as the parents for this commit. This array may be empty for the root commit. All the given commits must be owned by this repository.
		 * @see prettify_message
		 */
		[CCode(cname = "git_commit_create", instance_pos = 1.2)]
		public Error create_commit(object_id id, string? update_ref, Signature author, Signature committer, string? message_encoding, string message, Tree tree, [CCode(array_length_pos = 7.8)] Commit[] parents);

		/**
		 * Create a new commit in the repository using a variable argument list.
		 *
		 * The parents for the commit are specified as a variable arguments. Note
		 * that this is a convenience method which may not be safe to export for
		 * certain languages or compilers
		 *
		 * The message will be cleaned up from excess whitespace it will be made
		 * sure that the last line ends with a new line.
		 *
		 * All other parameters remain the same.
		 *
		 * @see create_commit
		 */
		[CCode(cname = "git_commit_create_v", instance_pos = 1.2)]
		public Error create_commit_v(object_id id, string update_ref, Signature author, Signature committer, string message_encoding, string message, Tree tree, int parent_count, ...);

		/**
		 * Create a new lightweight tag pointing at a target object
		 *
		 * A new direct reference will be created pointing to this target object.
		 * If //force// is true and a reference already exists with the given name,
		 * it'll be replaced.
		 *
		 * The message will be cleaned up from excess whitespace
		 * it will be made sure that the last line ends with a new line.
		 *
		 * @param id where to store the id of the newly created tag. If the tag already exists, this parameter will be the id of the existing tag, and the function will return a {@link Error.EXISTS} error code.
		 *
		 * @param tag_name Name for the tag; this name is validated for consistency. It should also not conflict with an already existing tag name.
		 *
		 * @param target Object to which this tag points. This object must belong to this repository.
		 *
		 * @param force Overwrite existing references
		 *
		 * @return on success, a proper reference is written in the ///refs/tags// folder, pointing to the provided target object
		 * @see create_tag
		 */
		[CCode(cname = "git_tag_create_lightweight", instance_pos = 1.2)]
		public Error create_lightweight_tag(object_id id, string tag_name, Object target, bool force);

		/**
		 * Add a note for an object
		 *
		 * @param note_id the object id of the note crated
		 * @param author signature of the notes commit author
		 * @param committer signature of the notes commit committer
		 * @param notes_ref ID reference to update (optional); defaults to "refs/notes/commits"
		 * @param id The ID of the object
		 * @param note The note to add for the object
		 * @param force Overwrite existing note
		 */
		[CCode(cname = "git_note_create", instance_pos = 1.2)]
		public Error create_note(out object_id note_id, Signature author, Signature committer, string? notes_ref, object_id id, string note, bool force = false);

		/**
		 * Creates a new iterator for notes.
		 *
		 * @param notes_ref canonical name of the reference to use (optional);
		 * defaults to "refs/notes/commits"
		 */
		[CCode(cname = "git_note_iterator_new", instance_pos = 1.1)]
		public Error create_note_iterator(out NoteIterator? iterator, string? notes_ref = null);

		/**
		 * Initialize a new packbuilder
		 *
		 * @param pack_builder The new packbuilder object
		 */
		[CCode(cname = "git_packbuilder_new", instance_pos = -1)]
		public Error create_pack_builder(out PackBuilder? pack_builder);

		/**
		 * Create a new reference database with no backends.
		 *
		 * Before the Ref DB can be used for read/writing, a custom database
		 * backend must be manually set using {@link RefDb.set_backend}.
		 */
		[CCode(cname = "git_refdb_new", instance_pos = -1)]
		public Error create_refdb(out RefDb? refdb);

		/**
		 * Create a new object id reference.
		 *
		 * The reference will be created in the repository and written to the disk.
		 *
		 * @param reference the newly created reference
		 * @param name The name of the reference
		 * @param id The object id pointed to by the reference.
		 * @param force Overwrite existing references
		 */
		[CCode(cname = "git_reference_create", instance_pos = 1.2)]
		public Error create_reference(out unowned Reference reference, string name, object_id id, bool force);

		/**
		 * Add a remote with the default fetch refspec to the repository's configuration.
		 *
		 * This calls {@link Remote.save} before returning.
		 *
		 * @param remote the resulting remote
		 * @param name the remote's name
		 * @param url the remote's url
		 */
		[CCode(cname = "git_remote_create", instance_pos = 1.2)]
		public Error create_remote(out Remote? remote, string name, string url);
		/**
		 * Create a remote with the given refspec in memory.
		 *
		 * You can use this when you have a URL instead of a remote's name.  Note
		 * that in-memory remotes cannot be converted to persisted remotes.
		 *
		 * @param remote the newly created remote reference
		 * @param fetch the fetch refspec to use for this remote; null for defaults
		 * @param url the remote repository's URL
		 */
		[CCode(cname = "git_remote_create_inmemory", instance_pos = 1.2)]
		public Error create_remote_in_memory(out Remote? remote, string? fetch, string url);

		/**
		 * Create a new symbolic reference.
		 *
		 * The reference will be created in the repository and written to the disk.
		 *
		 * @param reference the newly created reference
		 * @param name The name of the reference
		 * @param target The target of the reference
		 * @param force Overwrite existing references
		 */
		[CCode(cname = "git_reference_symbolic_create", instance_pos = 1.2)]
		public Error create_symbolic_reference(out unowned Reference reference, string name, string target, bool force);

		/**
		 * Create a new tag in the repository from an object
		 *
		 * A new reference will also be created pointing to this tag object. If
		 * //force// is true and a reference already exists with the given name,
		 * it'll be replaced.
		 *
		 * The tag name will be checked for validity. You must avoid the characters
		 * ~, ^, :, \, ?, [, and *, and the sequences '''..''' and '''@{''' which
		 * have special meaning to revparse.
		 *
		 * @param id where to store the id of the newly created tag. If the tag already exists, this parameter will be the id of the existing tag, and the function will return a {@link Error.EXISTS} error code.
		 * @param tag_name Name for the tag; this name is validated for consistency. It should also not conflict with an already existing tag name.
		 * @param target Object to which this tag points. This object must belong to this repository.
		 * @param tagger Signature of the tagger for this tag, and of the tagging time
		 * @param message Full message for this tag
		 * @param force Overwrite existing references
		 * @return on success, a tag object is written to the ODB, and a proper reference is written in the ///refs/tags// folder, pointing to it
		 */
		[CCode(cname = "git_tag_create", instance_pos = 1.2)]
		public Error create_tag(object_id id, string tag_name, Object target, Signature tagger, string message, bool force);

		/**
		 * Create a new tag in the repository from a buffer
		 *
		 * @param id Pointer where to store the id of the newly created tag
		 * @param buffer Raw tag data
		 * @param force Overwrite existing tags
		 * @see create_tag
		 */
		[CCode(cname = "git_tag_create_frombuffer", instance_pos = 1.2)]
		public Error create_tag_from_buffer(object_id id, string buffer, bool force);

		/**
		 * Delete an existing tag reference.
		 *
		 * @param tag_name Name of the tag to be deleted; this name is validated for consistency.
		 */
		[CCode(cname = "git_tag_delete")]
		public Error delete_tag(string tag_name);

		/**
		 * Detach the HEAD.
		 *
		 * If the HEAD is already detached and points to a commit, the call is successful.
		 *
		 * If the HEAD is already detached and points to a tag, the HEAD is updated
		 * into making it point to the peeled commit, and the call is successful.
		 *
		 * If the HEAD is already detached and points to a non commitish, the HEAD
		 * is unaletered, and an error is returned.
		 *
		 * Otherwise, the HEAD will be detached and point to the peeled commit.
		 */
		[CCode(cname = "git_repository_detach_head")]
		public Error detach_head();

		/**
		 * Compute a difference between two tree objects.
		 *
		 * @param diff The diff that will be allocated.
		 * @param old_tree A tree to diff from.
		 * @param new_tree A tree to diff to.
		 * @param opts Structure with options to influence diff or null for defaults.
		 */
		[CCode(cname = "git_diff_tree_to_tree", instance_pos = 1.1)]
		public Error diff_tree_to_tree(out DiffList? diff, Tree old_tree, Tree new_tree, diff_options? opts = null);

		/**
		 * Compute a difference between a tree and the index.
		 *
		 * @param diff The diff that will be allocated.
		 * @param old_tree A tree object to diff from.
		 * @param opts Structure with options to influence diff or null for defaults.
		 */
		[CCode(cname = "git_diff_tree_to_index", instance_pos = 1.1)]
		public Error diff_tree_to_index(out DiffList? diff, Tree old_tree, diff_options? opts = null);

		/**
		 * Compute a difference between the working directory and the index.
		 *
		 * @param diff A pointer to a git_diff_list pointer that will be allocated.
		 * @param opts Structure with options to influence diff or null for defaults.
		 */
		[CCode(cname = "git_diff_index_to_workdir", instance_pos = 1.1)]
		public Error diff_index_to_workdir(out DiffList? diff, diff_options? opts = null);

		/**
		 * Compute a difference between the working directory and a tree.
		 *
		 * Please note: this is //not// the same as '''git diff //treeish//'''.
		 * Running '''git diff HEAD''' or the like actually uses information from
		 * the index, along with the tree and working directory info.
		 *
		 * This function returns strictly the differences between the tree and the
		 * The tree you provide will be used for the {@link diff_delta.old_file}
		 * side of the delta, and the working directory will be used for the
		 * {@link diff_delta.new_file} side.
		 *
		 * Files contained in the working directory, regardless of the state of
		 * files in the index. It may come as a surprise, but there is no direct
		 * equivalent in core git.
		 *
		 * This is //not// the same as '''git diff HEAD''' or '''git diff <SHA>'''.
		 * Those commands diff the tree, the index, and the workdir. To emulate
		 * those functions, call {@link diff_tree_to_index} and
		 * {@link diff_index_to_workdir}, then call {@link DiffList.merge} on the
		 * results.
		 *
		 * If this seems confusing, take the case of a file with a staged deletion
		 * where the file has then been put back into the working dir and modified.
		 * The tree-to-workdir diff for that file is 'modified', but core git would
		 * show status 'deleted' since there is a pending deletion in the index.
		 *
		 * @param old_tree A tree to diff from.
		 * @param opts Structure with options to influence diff or NULL for defaults.
		 */
		[CCode(cname = "git_diff_workdir_to_tree", instance_pos = 1.1)]
		public Error diff_tree_to_workdir(out DiffList? diff, Tree old_tree, diff_options? opts = null);

		/**
		 * Remove a single stashed state from the stash list.
		 * @param index The position within the stash list. 0 points to the
		 * most recent stashed state.
		 */
		[CCode(cname = "git_stash_drop")]
		public Error drop_stash(size_t index);

		/**
		 * Iterate over each entry in the FETCH_HEAD file.
		 */
		[CCode(cname = "git_repository_fetchhead_foreach")]
		public Error for_each_fetchhead(FetchHeadForEach fetch_head_for_each);

		/**
		 * If a merge is in progress, iterate over each commit ID in the MERGE_HEAD
		 * file.
		 */
		[CCode(cname = "git_repository_mergehead_foreach")]
		public Error for_each_merge_head(MergeHeadForEach merge_head_for_each);

		/**
		 * Perform an operation on each reference in the repository
		 *
		 * The processed references may be filtered by type, or using a bitwise OR
		 * of several types. Use the magic value {@link ReferenceType.LISTALL} to
		 * obtain all references, including packed ones.
		 *
		 * @param list_flags Filtering flags for the reference listing.
		 * @param reference_for_each Function which will be called for every listed ref
		 */
		[CCode(cname = "git_reference_foreach")]
		public Error for_each_reference(ReferenceType list_flags, ReferenceForEach reference_for_each);
		/**
		 * Loop over all the references and issue a callback for each one which
		 * name matches the given glob pattern.
		 *
		 * @param list_flags Filtering flags for the reference listing.
		 * @param reference_for_each to invoke per found reference.
		 */
		[CCode(cname = "git_reference_foreach_glob")]
		public Error for_each_reference_glob(string glob, ReferenceType list_flags, ReferenceForEach reference_for_each);

		/**
		 * Iterate over all submodules of a repository.
		 */
		[CCode(cname = "git_submodule_foreach")]
		public Error for_each_submodule(SubmoduleForEach submodule_for_each);
		/**
		 * Iterate over each tag in the repository.
		 */
		[CCode(cname = "git_tag_foreach")]
		public Error for_each_tag(TagForEach tag_for_each);

		/**
		 * Find a merge base between two commits
		 *
		 * @param merge_base the OID of a merge base between 'one' and 'two'
		 * @param one one of the commits
		 * @param two the other commit
		 */
		[CCode(cname = "git_merge_base", instance_pos = 1.2)]
		public Error find_merge_base(out object_id merge_base, object_id one, object_id two);

		/**
		 * Find a merge base given a list of commits
		 *
		 * @param id the ID of a merge base considering all the commits
		 * @param input ids of the commits
		 */
		[CCode(cname = "git_merge_base_many", instance_pos = 1.1)]
		public Error find_merge_base_many(out object_id id, [CCode(array_length_type = "size_t")]object_id[] input);

		/**
		 * Loop over all the notes within a specified namespace.
		 * @param notes_ref OID reference to read from (optional); defaults to "refs/notes/commits".
		 */
		[CCode(cname = "git_note_foreach")]
		public Error for_each_note(string? notes_ref, NoteForEach note_for_each);

		/**
		 * Loop over all the stashed states.
		 *
		 * The most recent stash state will be enumerated first.
		 */
		[CCode(cname = "git_stash_foreach")]
		public Error for_each_stash(StashForEach stash_for_each);

		/**
		 * Gather file statuses and run a callback for each one.
		 *
		 * The callback is passed the path of the file, the status and the data
		 * pointer passed to this function. If the callback returns something other
		 * than {@link Error.OK}, this function will return that value.
		 *
		 * @param status_for_each the function to call on each file
		 * @return {@link Error.OK} or the return value of the callback
		 */
		[CCode(cname = "git_status_foreach")]
		public Error for_each_status(StatusForEach status_for_each);

		/**
		 * Gather file status information and run callbacks as requested.
		 */
		[CCode(cname = "git_status_foreach_ext")]
		public Error for_each_status_ext(status_options opts, StatusForEach status_for_each);

		/**
		 * Get the configuration file for this repository.
		 *
		 * If a configuration file has not been set, the default
		 * config set for the repository will be returned, including
		 * global and system configurations (if they are available).
		 *
		 * @param config the repository's configuration
		 */
		[CCode(cname = "git_repository_config", instance_pos = -1)]
		public Error get_config(out Config config);

		/**
		 * Get the Object Database for this repository.
		 *
		 * If a custom ODB has not been set, the default database for the
		 * repository will be returned (the one located in //.git/objects//).
		 */
		[CCode(cname = "git_repository_odb", instance_pos = -1)]
		public Error get_db(out Database.Handle db);

		/**
		 * Get file status for a single file
		 *
		 * @param status the status value
		 * @param path the file to retrieve status for, rooted at the repo's workdir
		 * @return {@link Error.ERROR} when //path// points at a folder, {@link Error.NOTFOUND} when the file doesn't exist in any of HEAD, the index or the worktree, {@link Error.OK} otherwise
		 */
		[CCode(cname = "git_status_file", instance_pos = 1.2)]
		public Error get_file_status(out Status status, string path);

		/**
		 * Retrieve and resolve the reference pointed at by HEAD.
		 *
		 * @param head the reference which will be retrieved
		 */
		[CCode(cname = "git_repository_head", instance_pos = -1)]
		public Error get_head(out Reference head);

		/**
		 * Get the index file for this repository.
		 *
		 * If a custom index has not been set, the default
		 * index for the repository will be returned (the one
		 * located in //.git/index//).
		 *
		 * If a custom index has not been set, the default
		 * index for the repository will be returned (the one
		 * located in //.git/index//).
		 *
		 */
		[CCode(cname = "git_repository_index", instance_pos = -1)]
		public void get_index(out Index index);

		/**
		 * Get the information for a particular remote
		 *
		 * The name will be checked for validity.
		 * @param remote the new remote object
		 * @param name the remote's name
		 * @see create_tag
		 */
		[CCode(cname = "git_remote_load", instance_pos = 1.2)]
		public Error get_remote(out Remote remote, string name);

		/**
		 * Return the name of remote that the remote tracking branch belongs to.
		 *
		 * @param remote_name The buffer which will be filled with the name of the
		 * remote. Pass null if you just want to get the needed size of the name of
		 * the remote as the output value.
		 *
		 * @param canonical_branch_name name of the remote tracking branch.
		 *
		 * @return Number of characters in the reference name including the
		 * trailing NUL byte; {@link Error.NOTFOUND} when no remote matching remote
		 * was found, {@link Error.AMBIGUOUS} when the branch maps to several
		 * remotes, otherwise an error code.
		 */
		[CCode(cname = "git_branch_remote_name", insance_pos = 1.2)]
		public int get_branch_remote_name([CCode(array_length_type = "size_t")] uint8[]? remote_name, string canonical_branch_name);

		/**
		 * Get the Reference Database Backend for this repository.
		 *
		 * If a custom refsdb has not been set, the default database for the
		 * repository will be returned (the one that manipulates loose and packed
		 * references in the '''.git''' directory).
		 */
		[CCode(cname = "git_repository_refdb", instance_pos = -1)]
		public Error get_refdb(out RefDb? refdb);

		/**
		 * Get a list of the configured remotes for a repo
		 *
		 * @param remotes_list a string array with the names of the remotes
		 */
		[CCode(cname = "git_remote_list", instance_pos = -1)]
		public Error get_remote_list(out string_array remotes_list);

		/**
		 * Fill a list with all the tags in the Repository
		 *
		 * @param tag_names where the tag names will be stored
		 */
		[CCode(cname = "git_tag_list", instance_pos = -1)]
		public Error get_tag_list(string_array tag_names);

		/**
		 * Fill a list with all the tags in the Repository which name match a
		 * defined pattern
		 *
		 * If an empty pattern is provided, all the tags will be returned.
		 *
		 * @param tag_names the tag names will be stored
		 * @param pattern standard shell-like (fnmatch) pattern
		 */
		[CCode(cname = "git_tag_list_match", instance_pos = -1)]
		public Error get_tag_list_match(out string_array tag_names, string pattern);

		/**
		 * Return the name of the reference supporting the remote tracking branch,
		 * given the name of a local branch reference.
		 *
		 * @param tracking_branch_name The buffer which will be filled with the
		 * name of the reference, or null if you just want to get the needed size
		 * of the name of the reference as the output value.
		 *
		 * @param canonical_branch_name name of the local branch.
		 *
		 * @return number of characters in the reference name including the
		 * trailing NUL byte; otherwise an error code.
		 */
		[CCode(cname = "git_branch_tracking_name", instance_pos = 1.3)]
		public int get_tracking_branch_name([CCode(array_length_type = "size_t")] char[]? tracking_branch_name, string canonical_branch_name);

		/**
		 * Allocate a new revision walker to iterate through a repo.
		 *
		 * This revision walker uses a custom memory pool and an internal commit
		 * cache, so it is relatively expensive to allocate.
		 *
		 * For maximum performance, this revision walker should be reused for
		 * different walks.
		 *
		 * This revision walker is ''not'' thread safe: it may only be used to walk
		 * a repository on a single thread; however, it is possible to have several
		 * revision walkers in several different threads walking the same
		 * repository.
		 *
		 * @param walker the new revision walker
		 */
		[CCode(cname = "git_revwalk_new", instance_pos = -1)]
		public Error get_walker(out RevisionWalker walker);

		/**
		 * Calculate hash of file using repository filtering rules.
		 *
		 * If you simply want to calculate the hash of a file on disk with no filters,
		 * you can just use the {@link object_id.hashfile} API. However, if you
		 * want to hash a file in the repository and you want to apply filtering
		 * rules (e.g. crlf filters) before generating the SHA, then use this
		 * function.
		 *
		 * @param path Path to file on disk whose contents should be hashed. This can be a relative path.
		 * @param type The object type to hash
		 * @param as_path The path to use to look up filtering rules. If this is
		 * null, then the path parameter will be used instead. If this is passed as
		 * the empty string, then no filters will be applied when calculating the
		 * hash.
		 */
		[CCode(cname = "git_repository_hashfile", instance_pos = 1.1)]
		public Error hashfile(out object_id id, string path, ObjectType type, string? as_path = null);

		/**
		 * Iterate over the branches in the repository.
		 *
		 * @param list_flags Filtering flags for the branch listing.
		 */
		[CCode(cname = "git_branch_foreach")]
		public Error for_each_branch(BranchType list_flags, Branch branch);
		/**
		 * Test if the ignore rules apply to a given path.
		 *
		 * This function checks the ignore rules to see if they would apply to the
		 * given file. This indicates if the file would be ignored regardless of
		 * whether the file is already in the index or commited to the repository.
		 *
		 * One way to think of this is if you were to do '''git add .''' on the
		 * directory containing the file, would it be added or not?
		 *
		 * @param path the file to check ignores for, relative to the repo's
		 * workdir.
		 */
		[CCode(cname = "git_ignore_path_is_ignored", instance_pos = 1.1)]
		public Error is_path_ignored(out bool ignored, string path);

		[CCode(cname = "git_branch_foreach", instance_pos = 1.2)]
		public Error list_branches(out string_array branch_names, BranchType list_flags);

		/**
		 * Fill a list with all the references that can be found
		 * in a repository.
		 *
		 * The listed references may be filtered by type, or using
		 * a bitwise OR of several types. Use the magic value
		 * {@link ReferenceType.LISTALL} to obtain all references, including
		 * packed ones.
		 *
		 * @param array where the reference names will be stored
		 * @param list_flags Filtering flags for the reference listing.
		 */
		[CCode(cname = "git_reference_listall", instance_pos = 1.2)]
		public Error list_all(out string_array array, ReferenceType list_flags);

		/**
		 * Convert a tree entry to the object it points too.
		 *
		 * @param object pointer to the converted object
		 * @param entry a tree entry
		 */
		[CCode(cname = "git_tree_entry_to_object", instance_pos = 1.2)]
		public Error load(out Object object, TreeEntry entry);

		/**
		 * Lookup a blob object from a repository.
		 *
		 * @param blob the looked up blob
		 * @param id identity of the blob to locate.
		 */
		[CCode(cname = "git_blob_lookup", instance_pos = 1.2)]
		public Error lookup_blob(out Blob blob, object_id id);

		/**
		 * Lookup a blob object from a repository, given a prefix of its identifier
		 * (short id).
		 *
		 * @see lookup_object_by_prefix
		 *
		 * @param blob the looked up blob
		 * @param id identity of the blob to locate.
		 * @param len the length of the short identifier
		 */
		[CCode(cname = "git_blob_lookup_prefix", instance_pos = 1.2)]
		public Error lookup_blob_by_prefix(out Blob blob, object_id id, size_t len);
		/**
		 * Lookup a branch by its name.
		 *
		 * @param branch_name Name of the branch to be looked-up; this name is
		 * validated for consistency.
		 */
		[CCode(cname = "git_branch_lookup", instance_pos = 1.1)]
		public Error lookup_branch(out Reference? branch, string branch_name, BranchType branch_type);

		/**
		 * Lookup a commit object from a repository.
		 *
		 * @param commit the looked up commit
		 * @param id identity of the commit to locate. If the object is an annotated tag it will be peeled back to the commit.
		 */
		[CCode(cname = "git_commit_lookup", instance_pos = 1.2)]
		public Error lookup_commit(out Commit commit, object_id id);

		/**
		 * Lookup a commit object from a repository, given a prefix of its
		 * identifier (short id).
		 *
		 * @see lookup_object_by_prefix
		 *
		 * @param commit the looked up commit
		 * @param id identity of the commit to locate. If the object is an annotated tag it will be peeled back to the commit.
		 * @param len the length of the short identifier
		 */
		[CCode(cname = "git_commit_lookup_prefix", instance_pos = 1.2)]
		public Error lookup_commit_by_prefix(out Commit commit, object_id id, size_t len);

		/**
		 * Lookup a reference to one of the objects in a repostory.
		 *
		 * The //type// parameter must match the type of the object in the ODB; the
		 * method will fail otherwise. The special value {@link ObjectType.ANY}
		 * may be passed to let the method guess the object's type.
		 *
		 * @param object the looked-up object
		 * @param id the unique identifier for the object
		 * @param type the type of the object
		 * @return a reference to the object
		 */
		[CCode(cname = "git_object_lookup", instance_pos = 1.2)]
		public Error lookup_object(out Object object, object_id id, ObjectType type);

		/**
		 * Lookup a reference to one of the objects in a repostory, given a prefix
		 * of its identifier (short id).
		 *
		 * The object obtained will be so that its identifier matches the first
		 * //len// hexadecimal characters (packets of 4 bits) of the given //id//.
		 * //len// must be at least {@link object_id.MIN_PREFIX_LENGTH}, and long
		 * enough to identify a unique object matching the prefix; otherwise the
		 * method will fail.
		 *
		 * The //type// parameter must match the type of the object in the ODB; the
		 * method will fail otherwise. The special value {@link ObjectType.ANY}
		 * may be passed to let the method guess the object's type.
		 *
		 * @param object where to store the looked-up object
		 * @param id a short identifier for the object
		 * @param len the length of the short identifier
		 * @param type the type of the object
		 */
		[CCode(cname = "git_object_lookup_prefix", instance_pos = 1.2)]
		public Error lookup_object_by_prefix(out Object object, object_id id, size_t len, ObjectType type);

		/**
		 * Lookup a reference by its name in a repository.
		 *
		 * @param reference the looked-up reference
		 * @param name the long name for the reference (e.g., HEAD, ref/heads/master, refs/tags/v0.1.0, ...)
		 */
		[CCode(cname = "git_reference_lookup", instance_pos = 1.2)]
		public Error lookup_reference(out Reference reference, string name);

		/**
		 * Lookup a reference by name and resolve immediately to an ID.
		 *
		 * @param name The long name for the reference
		 */
		[CCode(cname = "git_reference_name_to_id", instance_pos = 1.2)]
		public Error lookup_reference_to_id(out object_id id, string name);

		/**
		 * Lookup submodule information by name or path.
		 *
		 * Given either the submodule name or path (they are ususally the same),
		 * this returns a structure describing the submodule.
		 *
		 * @param name The name of the submodule. Trailing slashes will be ignored.
		 */
		[CCode(cname = "git_submodule_lookup", instance_pos = 1.2)]
		public Error lookup_submodule(out unowned Submodule? submodule, string name);

		/**
		 * Lookup a tag object from the repository.
		 *
		 * @param tag pointer to the looked up tag
		 * @param id identity of the tag to locate.
		 */
		[CCode(cname = "git_tag_lookup", instance_pos = 1.2)]
		public Error lookup_tag(out Tag tag, object_id id);

		/**
		 * Lookup a tag object from the repository, given a prefix of its
		 * identifier (short id).
		 *
		 * @see lookup_object_by_prefix
		 *
		 * @param tag pointer to the looked up tag
		 * @param id identity of the tag to locate.
		 * @param len the length of the short identifier
		 */
		[CCode(cname = "git_tag_lookup_prefix", instance_pos = 1.2)]
		public Error prefix_lookup_tag(out Tag tag, object_id id, uint len);

		/**
		 * Lookup a tree object from the repository.
		 *
		 * @param tree the looked up tree
		 * @param id identity of the tree to locate.
		 */
		[CCode(cname = "git_tree_lookup", instance_pos = 1.2)]
		public Error lookup_tree(out Tree tree, object_id id);

		/**
		 * Lookup a tree object from the repository, given a prefix of its
		 * identifier (short id).
		 *
		 * @see lookup_object_by_prefix
		 *
		 * @param tree the looked up tree
		 * @param id identity of the tree to locate.
		 * @param len the length of the short identifier
		 */
		[CCode(cname = "git_tree_lookup_prefix", instance_pos = 1.2)]
		public Error lookup_tree_by_prefix(out Tree tree, object_id id, uint len);

		/**
		 * Create a new reference database and automatically add
		 * the default backends:
		 *
		 * - git_refdb_dir: read and write loose and packed refs from disk,
		 * assuming the repository dir as the folder
		 */
		 [CCode(cname = "git_refdb_open", instance_pos = -1)]
		 public Error open_refdb(out RefDb? refdb);

		/**
		 * Find an object, as specified by a revision string. See the gitrevisions
		 * manual page, or the documentation for '''git rev-parse''' for
		 * information on the syntax accepted.
		 *
		 * @param spec the textual specification for an object
		 */
		[CCode(cname = "git_revparse_single", instance_pos = 1.1)]
		public Error parse(out Object? obj, string spec);

		/**
		 * Read the note for an object
		 * @param notes_ref ID reference to use (optional); defaults to "refs/notes/commits"
		 * @param id ID of the object
		 */
		[CCode(cname = "git_note_read", instance_pos = 1.2)]
		public Error read_note(out Note? note, string? notes_ref, object_id id);
		/**
		 * Get the default notes reference for a repository
		 */
		[CCode(cname = "git_note_default_ref", instance_pos = -1)]
		public Error read_note_default_ref(out unowned string note);

		/**
		 * Reread all submodule info.
		 *
		 * Call this to reload all cached submodule information for the repo.
		 */
		[CCode(cname = "git_submodule_reload_all")]
		public Error reload_submodules();

		/**
		 * Remove the note for an object
		 *
		 * @param notes_ref ID reference to use (optional); defaults to "refs/notes/commits"
		 * @param author signature of the notes commit author
		 * @param committer signature of the notes commit committer
		 * @param id the id which note's to be removed
		 */
		[CCode(cname = "git_note_remove")]
		public Error remove_note(string? notes_ref, Signature author, Signature committer, object_id id);

		/**
		 * Sets the current head to the specified commit oid and optionally resets
		 * the index and working tree to match.
		 *
		 * When specifying a Soft kind of reset, the head will be moved to the commit.
		 *
		 * Specifying a Mixed kind of reset will trigger a Soft reset and the index
		 * will be replaced with the content of the commit tree.
		 *
		 * @param target Object to which the Head should be moved to. This object
		 * must belong to this repository and can either be a {@link Commit} or a
		 * {@link Tag}. When a {@link Tag} is being passed, it should be
		 * dereferencable to a {@link Commit} which oid will be used as the target
		 * of the branch.
		 * @param reset_type Kind of reset operation to perform.
		 */
		[CCode(cname = "git_reset")]
		public Error reset(Object target, ResetType reset_type);

		/**
		 * Updates some entries in the index from the target commit tree.
		 *
		 * The scope of the updated entries is determined by the paths
		 * specified.
		 *
		 * @param target The committish which content will be used to reset the
		 * content of the index. Passing null will result in removing entries in
		 * the index matching the provided pathspecs.
		 *
		 * @param pathspecs List of pathspecs to operate on.
		 */
		[CCode(cname = "git_reset_default")]
		public Error reset_default(Object? target, string_array pathspecs);

		/**
		 * Save the local modifications to a new stash.
		 *
		 * @param id id of the commit containing the stashed state. This commit is
		 * also the target of the direct reference refs/stash.
		 * @param stasher The identity of the person performing the stashing.
		 * @param message description along with the stashed state.
		 */
		[CCode(cname = "git_stash_save", instance_pos = 1.1)]
		public Error save_stash(out object_id id, Signature stasher, string? message = null, StashFlag flags = StashFlag.DEFAULT);

		/**
		 * Set the configuration file for this repository
		 *
		 * This configuration file will be used for all configuration
		 * queries involving this repository.
		 */
		[CCode(cname = "git_repository_set_config")]
		public void set_config(Config config);

		/**
		 * Set the Object Database for this repository
		 *
		 * The ODB will be used for all object-related operations involving this
		 * repository.
		 */
		[CCode(cname = "git_repository_set_odb")]
		public void set_db(Database.Handle db);
		/**
		 * Make the repository HEAD point to the specified reference.
		 *
		 * If the provided reference points to a Tree or a Blob, the HEAD is
		 * unaltered and an error is returned.
		 *
		 * If the provided reference points to a branch, the HEAD will point to
		 * that branch, staying attached, or become attached if it isn't yet. If
		 * the branch doesn't exist yet, no error will be return. The HEAD will
		 * then be attached to an unborn branch.
		 *
		 * Otherwise, the HEAD will be detached and will directly point to the
		 * Commit.
		 *
		 * @param refname Canonical name of the reference the HEAD should point at
		 */
		[CCode(cname = "git_repository_set_head")]
		public Error set_head(string refname);

		/**
		 * Make the repository HEAD directly point to the Commit.
		 *
		 * If the provided committish cannot be found in the repository, the HEAD
		 * is unaltered and {@link Error.NOTFOUND} is returned.
		 *
		 * If the provided commitish cannot be peeled into a commit, the HEAD is
		 * unaltered and and error is returned.
		 *
		 * Otherwise, the HEAD will eventually be detached and will directly point to
		 * the peeled Commit.
		 *
		 * @param commitish Object id of the Commit the HEAD should point to
		 * @return 0 on success, or an error code
		 */
		[CCode(cname = "git_repository_set_head_detached")]
		public Error set_head_detached(object_id commitish);

		/**
		 * Set the index file for this repository
		 *
		 * This index will be used for all index-related operations
		 * involving this repository.
		 */
		[CCode(cname = "git_repository_set_index")]
		public void set_index(Index index);

		/**
		 * Set the Reference Database Backend for this repository
		 *
		 * The refdb will be used for all reference related operations involving
		 * this repository.
		 */
		[CCode(cname = "git_repository_set_refdb")]
		public void set_refdb(RefDb refdb);

		/**
		 * Set the working directory.
		 * @param workdir The path to a working directory
		 * @param update_gitlink Create/update gitlink in workdir and set config
		 * "core.worktree" (if workdir is not the parent of the .git directory)
		 */
		[CCode(cname = "git_repository_set_workdir")]
		public Error set_workdir(string workdir, bool update_gitlink);

		/**
		 * Test if the ignore rules apply to a given file.
		 *
		 * This function simply checks the ignore rules to see if they would apply
		 * to the given file. Unlike {@link get_file_status}, this indicates if
		 * the file would be ignored regardless of whether the file is already in
		 * the index or in the repository.
		 *
		 * @param path the file to check ignores for, rooted at the repo's workdir
		 * @param ignored false if the file is not ignored, true if it is
		 * @return {@link Error.OK} if the ignore rules could be processed
		 * for the file (regardless of whether it exists or not), or an error if
		 * they could not.
		 */
		[CCode(cname = "git_status_should_ignore", instance_pos = 1.2)]
		public Error should_ignore(out bool ignored, string path);

		/**
		 * Write the contents of the tree builder as a tree object
		 *
		 * The tree builder will be written to the repositrory, and it's
		 * identifying SHA1 hash will be stored in the id pointer.
		 *
		 * @param id Pointer where to store the written id
		 * @param builder Tree builder to write
		 */
		[CCode(cname = "git_treebuilder_write", instance_pos = 1.2)]
		public Error write(object_id id, TreeBuilder builder);

	}

	/**
	 * An in-progress walk through the commits in a repo
	 */
	[CCode(cname = "git_revwalk", free_function = "git_revwalk_free", has_type_id = false)]
	[Compact]
	public class RevisionWalker {

		/**
		 * The repository on which this walker is operating.
		 */
		public Repository repository {
			[CCode(cname = "git_revwalk_repository")]
			get;
		}

		/**
		 * Mark a commit (and its ancestors) uninteresting for the output.
		 *
		 * The given id must belong to a commit on the walked repository.
		 *
		 * The resolved commit and all its parents will be hidden from the output
		 * on the revision walk.
		 *
		 * @param id the id of commit that will be ignored during the traversal
		 */
		[CCode(cname = "git_revwalk_hide")]
		public Error hide(object_id id);

		/**
		 * Hide the OID pointed to by a reference
		 *
		 * The reference must point to a commit.
		 *
		 * @param refname the referece to hide
		 */
		[CCode(cname = "git_revwalk_hide_ref")]
		public Error hide_ref(string refname);

		/**
		 * Get the next commit from the revision walk.
		 *
		 * The initial call to this method is ''not'' blocking when iterating through
		 * a repo with a time-sorting mode.
		 *
		 * Iterating with topological or inverted modes makes the initial call
		 * blocking to preprocess the commit list, but this block should be mostly
		 * unnoticeable on most repositories (topological preprocessing times at
		 * 0.3s on the git.git repo).
		 *
		 * The revision walker is reset when the walk is over.
		 *
		 * @param id where to store the id of the next commit
		 */
		[CCode(cname = "git_revwalk_next", instance_pos = -1)]
		public Error next(out object_id id);

		/**
		 * Mark a commit to start traversal from.
		 *
		 * The given id must belong to a commit on the walked repository.
		 *
		 * The given commit will be used as one of the roots when starting the
		 * revision walk. At least one commit must be pushed the repository before
		 * a walk can be started.
		 *
		 * @param id the id of the commit to start from.
		 */
		[CCode(cname = "git_revwalk_push")]
		public Error push(object_id id);

		/**
		 * Push the OID pointed to by a reference
		 *
		 * The reference must point to a commit.
		 *
		 * @param refname the referece to push
		 */
		[CCode(cname = "git_revwalk_push_ref")]
		public Error push_ref(string refname);

		/**
		 * Push matching references
		 *
		 * The OIDs pinted to by the references that match the given glob
		 * pattern will be pushed to the revision walker.
		 *
		 * A leading 'refs/' is implied it not present as well as a trailing
		 * '/ *' if the glob lacks '?', '*' or '['.
		 *
		 * @param glob the glob pattern references should match
		 */
		[CCode(cname = "git_revwalk_push_glob")]
		public Error push_glob(string glob);

		/**
		 * Push the repository's HEAD
		 */
		[CCode(cname = "git_revwalk_push_head")]
		public Error push_head();

		/**
		 * Reset the revision walker for reuse.
		 *
		 * This will clear all the pushed and hidden commits, and leave the walker
		 * in a blank state (just like at creation) ready to receive new commit
		 * pushes and start a new walk.
		 *
		 * The revision walk is automatically reset when a walk is over.
		 */
		[CCode(cname = "git_revwalk_reset")]
		public void reset();

		/**
		 * Change the sorting mode when iterating through the repository's
		 * contents.
		 *
		 * Changing the sorting mode resets the walker.
		 *
		 * @param sort combination of sort flags
		 */
		[CCode(cname = "git_revwalk_sorting")]
		public void set_sorting(Sorting sort);

		/**
		 * Hide matching references.
		 *
		 * The OIDs pinted to by the references that match the given glob
		 * pattern and their ancestors will be hidden from the output on the
		 * revision walk.
		 *
		 * A leading 'refs/' is implied it not present as well as a trailing
		 * '/ *' if the glob lacks '?', '*' or '['.
		 *
		 * @param glob the glob pattern references should match
		 */
		[CCode(cname = "git_revwalk_hide_glob")]
		public Error hide_glob(string glob);

		/**
		 * Hide the repository's HEAD
		 */
		[CCode(cname = "git_revwalk_hide_head")]
		public Error hide_head();
	}

	/**
	 * An action signature (e.g. for committers, taggers, etc)
	 */
	[CCode(cname = "git_signature", free_function = "git_signature_free", copy_function = "git_signature_dup", has_type_id = false)]
	[Compact]
	public class Signature {
		/**
		 * Email of the author
		 */
		public string email;
		/**
		 * Full name of the author
		 */
		public string name;
		/**
		 * Time when the action happened
		 */
		public time when;

		/**
		 * Create a new action signature.
		 *
		 * Note: angle brackets characters are not allowed in either the name or
		 * the email.
		 * @param sig new signature, null in case of error
		 * @param name name of the person
		 * @param email email of the person
		 * @param time time when the action happened
		 * @param offset timezone offset in minutes for the time
		 */
		[CCode(cname = "git_signature_new")]
		public static int create(out Signature? sig, string name, string email, int64 time, int offset);

		/**
		 * Create a new action signature with a timestamp of now.
		 *
		 * @param sig new signature, null in case of error
		 * @param name name of the person
		 * @param email email of the person
		 */
		[CCode(cname = "git_signature_now")]
		public static int create_now(out Signature? sig, string name, string email);
	}

	/**
	 * Description of submodule
	 *
	 * This record describes a submodule found in a repository. There
	 * should be an entry for every submodule found in the HEAD and for
	 * every submodule described in .gitmodules.
	 */
	[CCode(cname = "git_submodule", has_type_id = false)]
	[Compact]
	public class Submodule {
		/**
		 * The name of the submodule from .gitmodules.
		 */
		public string name {
			[CCode(cname = "git_submodule_name")]
			get;
		}
		/**
		 * The path to the submodule from the repo working directory.
		 *
		 * It is almost always the same as {@link name}.
		 */
		public string path {
			[CCode(cname = "git_submodule_path")]
			get;
		}
		/**
		 * The url for the submodule.
		 *
		 * If deleted but not commited, this will be null.
		 */
		public string? url {
			[CCode(cname = "git_submodule_url")]
			get;
			[CCode(cname = "git_submodule_set_url")]
			set;
		}
		/**
		 * Get the OID for the submodule in the index.
		 */
		public object_id? index_id {
			[CCode(cname = "git_submodule_index_id")]
			get;
		}
		/**
		 * Get the OID for the submodule in the current HEAD tree.
		 */
		public object_id? head_id {
			[CCode(cname = "git_submodule_head_id")]
			get;
		}
		/**
		 * Whether or not to fetch submodules of submodules recursively.
		 */
		public bool fetch_recurse {
			[CCode(cname = "git_submodule_fetch_recurse_submodules")]
			get;
			[CCode(cname = "git_submodule_set_fetch_recurse_submodules")]
			set;
		}
		/**
		 * The containing repository for a submodule.
		 *
		 * This returns a pointer to the repository that contains the submodule.
		 */
		public Repository repository {
			[CCode(cname = "git_submodule_owner")]
			get;
		}

		/**
		 * Get the OID for the submodule in the current working directory.
		 *
		 * This returns the OID that corresponds to looking up 'HEAD' in the
		 * checked out submodule. If there are pending changes in the index or
		 * anything else, this won't notice that. You should check
		 * {@link status} for a more complete picture about the state of the
		 * working directory.
		 */
		public object_id? wd_id {
			[CCode(cname = "git_submodule_wd_id")]
			get;
		}

		/**
		 * The ignore rule for the submodule.
		 */
		[CCode(cname = "git_submodule_ignore")]
		public SubmoduleIgnore ignore {
			[CCode(cname = "git_submodule_ignore")]
			get;
			[CCode(cname = "git_submodule_set_ignore")]
			set;
		}

		/**
		 * The update rule for the submodule.
		 */
		public SubmoduleUpdate update {
			[CCode(cname = "git_submodule_update")]
			get;
			[CCode(cname = "git_submodule_set_update")]
			set;
		}

		/**
		 * Resolve the setup of a new git submodule.
		 *
		 * This should be called on a submodule once you have called add setup and
		 * done the clone of the submodule. This adds the .gitmodules file and the
		 * newly cloned submodule to the index to be ready to be committed (but
		 * doesn't actually do the commit).
		 */
		[CCode(cname = "git_submodule_add_finalize")]
		public Error add_finalize();

		/**
		 * Add current submodule HEAD commit to index of superproject.
		 *
		 * @param write_index if this should immediately write the index file. If
		 * you pass this as false, you will have to explicitly call {@link Index.write}
		 * on it to save the change.
		 */
		[CCode(cname = "git_submodule_add_to_index")]
		public Error add_to_index(bool write_index);

		/**
		 * Copy submodule info into ".git/config" file.
		 *
		 * Just like "git submodule init", this copies information about the
		 * submodule into ".git/config". You can use the accessor functions above
		 * to alter the in-memory git_submodule object and control what is written
		 * to the config, overriding what is in .gitmodules.
		 *
		 * @param overwrite By default, existing entries will not be overwritten,
		 * but setting this to true forces them to be updated.
		 */
		[CCode(cname = "git_submodule_init")]
		public Error init(bool overwrite);

		/**
		 * Get the locations of submodule information.
		 *
		 * This is a bit like a very lightweight version of {@link status}.
		 * It just returns a made of the first four submodule status values (i.e.
		 * the ones like {@link SubmoduleStatus.IN_HEAD}, etc) that tell you where
		 * the submodule data comes from (i.e. the HEAD commit, gitmodules file,
		 * etc.).
		 *
		 * This can be useful if you want to know if the submodule is present in
		 * the working directory at this point in time, etc.
		 */
		[CCode(cname = "git_submodule_location", instance_pos = -1)]
		public Error location(out SubmoduleStatus status);

		/**
		 * Copy submodule remote info into submodule repo.
		 *
		 * This copies the information about the submodules URL into the checked
		 * out submodule config, acting like "git submodule sync". This is useful
		 * if you have altered the URL for the submodule (or it has been altered by
		 * a fetch of upstream changes) and you need to update your local repo.
		 */
		[CCode(cname = "git_submodule_sync")]
		public Error sync();

		/**
		 * Open the repository for a submodule.
		 *
		 * This will only work if the submodule is checked out into the working
		 * directory.
		 */
		[CCode(cname = "git_submodule_open", instance_pos = -1)]
		public Error open(out Repository? repo);

		/**
		 * Reread submodule info from config, index, and HEAD.
		 *
		 * Call this to reread cached submodule information for this submodule if
		 * you have reason to believe that it has changed.
		 */
		[CCode(cname = "git_submodule_reload")]
		public Error reload();

		/**
		 * Write submodule settings to .gitmodules file.
		 *
		 * This commits any in-memory changes to the submodule to the gitmodules
		 * file on disk. You may also be interested in `git_submodule_init()`
		 * which writes submodule info to ".git/config" (which is better for local
		 * changes to submodule settings) and/or `git_submodule_sync()` which
		 * writes settings about remotes to the actual submodule repository.
		 */
		 [CCode(cname = "git_submodule_save")]
		 public Error save();

		/**
		 * Get the status for a submodule.
		 *
		 * This looks at a submodule and tries to determine the status.
		 */
		[CCode(cname = "git_submodule_status", instance_pos = -1)]
		public Error status(out SubmoduleStatus status);
	}

	/**
	 * Parsed representation of a tag object.
	 */
	[CCode(cname = "git_tag", free_function = "git_tag_free", has_type_id = false)]
	[Compact]
	public class Tag : Object {
		/**
		 * The id of a tag.
		 */
		public object_id? id {
			[CCode(cname = "git_tag_id")]
			get;
		}

		/**
		 * The message of a tag
		 */
		public string message {
			[CCode(cname = "git_tag_message")]
			get;
		}

		/**
		 * The name of a tag
		 */
		public string name {
			[CCode(cname = "git_tag_name")]
			get;
		}

		/**
		 * The tagger (author) of a tag
		 */
		public Signature tagger {
			[CCode(cname = "git_tag_tagger")]
			get;
		}

		/**
		 * The id of the tagged object of a tag
		 */
		public object_id? target_id {
			[CCode(cname = "git_tag_target_id")]
			get;
		}

		/**
		 * The type of a tag's tagged object
		 */
		public ObjectType target_type {
			[CCode(cname = "git_tag_target_type")]
			get;
		}

		/**
		 * Get the tagged object of a tag
		 *
		 * This method performs a repository lookup for the given object and
		 * returns it
		 *
		 * @param target where to store the target
		 */
		[CCode(cname = "git_tag_target", instance_pos = -1)]
		public Error lookup_target(out Object target);

		/**
		 * Recursively peel a tag until a non-tag-object is met
		 */
		[CCode(cname = "git_tag_peel", instance_pos = -1)]
		public Error peel(out Object result);
	}

	/**
	 * Representation of a tree object.
	 */
	[CCode(cname = "git_tree", free_function = "git_tree_free", has_type_id = false)]
	[Compact]
	public class Tree : Object {
		/**
		 * The id of a tree.
		 */
		public object_id? id {
			[CCode(cname = "git_tree_id")]
			get;
		}

		public Repository repository {
			[CCode(cname = "git_tree_owner")]
			get;
		}

		/**
		 * Get the number of entries listed in a tree
		 */
		public size_t size {
			[CCode(cname = "git_tree_entrycount")]
			get;
		}

		/**
		 * Lookup a tree entry by its position in the tree
		 *
		 * @param idx the position in the entry list
		 * @return the tree entry; null if not found
		 */
		[CCode(cname = "git_tree_entry_byindex")]
		public unowned TreeEntry? get(size_t idx);
		/**
		 * Lookup a tree entry by SHA value.
		 *
		 * Warning: this must examine every entry in the tree, so it is not fast.
		 *
		 * @param id the sha being looked for
		 * @return the tree entry; null if not found
		 */
		[CCode(cname = "git_tree_entry_byoid")]
		public unowned TreeEntry? get_by_id(object_id id);

		/**
		 * Lookup a tree entry by its filename
		 *
		 * @param filename the filename of the desired entry
		 * @return the tree entry; null if not found
		 */
		[CCode(cname = "git_tree_entry_byname")]
		public unowned TreeEntry? get_by_name(string filename);

		/**
		 * Retrieve a subtree contained in a tree, given its relative path.
		 *
		 * @param path Path to the tree entry from which to extract the last tree object
		 * @return {@link Error.OK} on success; {@link Error.NOTFOUND} if the path does not lead to an entry; otherwise, an error code
		 */
		[CCode(cname = "git_tree_entry_bypath", instance_pos = 1.2)]
		public Error get_by_path(out TreeEntry entry, string path);

		/**
		 * Traverse the entries in a tree and its subtrees in post or pre order
		 *
		 * The entries will be traversed in the specified order, children subtrees
		 * will be automatically loaded as required, and the callback will be
		 * called once per entry with the current (relative) root for the entry and
		 * the entry data itself.
		 *
		 * If the callback returns a negative value, the passed entry will be
		 * skiped on the traversal.
		 *
		 * @param mode Traversal mode (pre or post-order)
		 * @param tree_walker Function to call on each tree entry
		 */
		[CCode(cname = "git_tree_walk")]
		public Error walk(WalkMode mode, TreeWalker tree_walker);
	}

	/**
	 * Constructor for in-memory trees
	 */
	[CCode(cname = "git_treebuilder", free_function = "git_treebuilder_free", has_type_id = false)]
	[Compact]
	public class TreeBuilder {
		/**
		 * The number of entries listed in a treebuilder.
		 */
		public uint size {
			[CCode(cname = "git_treebuilder_entrycount")]
			get;
		}

		/**
		 * Create a new tree builder.
		 *
		 * The tree builder can be used to create or modify trees in memory and
		 * write them as tree objects to the database.
		 *
		 * If the source parameter is not null, the tree builder will be
		 * initialized with the entries of the given tree.
		 *
		 * If the source parameter is null, the tree builder will have no entries
		 * and will have to be filled manually.
		 *
		 * @param builder where to store the tree builder
		 * @param source source tree to initialize the builder (optional)
		 */
		[CCode(cname = "git_treebuilder_create")]
		public static Error create(out TreeBuilder builder, Tree? source = null);

		/**
		 * Clear all the entires in the builder
		 */
		[CCode(cname = "git_treebuilder_clear")]
		public void clear();

		/**
		 * Filter the entries in the tree
		 *
		 * The filter will be called for each entry in the tree with an entry. If
		 * the callback returns true, the entry will be filtered (removed from the
		 * builder).
		 * @param filter function to filter entries
		 */
		[CCode(cname = "git_treebuilder_filter")]
		public void filter(Filter filter);

		/**
		 * Add or update an entry to the builder
		 *
		 * Insert a new entry for the given filename in the builder with the given
		 * attributes.
		 *
		 * If an entry named filename already exists, its attributes will be
		 * updated with the given ones.
		 *
		 * @param entry where to store the entry (optional)
		 * @param filename Filename of the entry
		 * @param id SHA1 id of the entry
		 * @param attributes Folder attributes of the entry
		 * @return 0 on success; error code otherwise
		 */
		[CCode(cname = "git_treebuilder_insert", instance_pos = 1.2)]
		public Error insert(out unowned TreeEntry? entry = null, string filename, object_id id, Attributes attributes);

		/**
		 * Get an entry from the builder from its filename
		 * @param filename Name of the entry
		 * @return the entry; null if not found
		 */
		[CCode(cname = "git_treebuilder_get")]
		public unowned TreeEntry? get(string filename);

		/**
		 * Remove an entry from the builder by its filename
		 *
		 * @param filename Filename of the entry to remove
		 */
		[CCode(cname = "git_treebuilder_remove")]
		public Error remove(string filename);
	}

	/**
	 * Representation of each one of the entries in a tree object.
	 */
	[CCode(cname = "git_tree_entry", has_type_id = false, free_function = "git_tree_entry_free", copy_function = "git_tree_entry_dup")]
	[Compact]
	public class TreeEntry {

		/**
		 * The id of the object pointed by the entry
		 */
		public unowned object_id? id {
			[CCode(cname = "git_tree_entry_id")]
			get;
		}

		/**
		 * The filename of a tree entry
		 */
		public string name {
			[CCode(cname = "git_tree_entry_name")]
			get;
		}

		/**
		 * The UNIX file attributes of a tree entry
		 */
		public FileMode mode {
			[CCode(cname = "git_tree_entry_filemode")]
			get;
		}

		/**
		 * The type of the object pointed by the entry
		 */
		public ObjectType type {
			[CCode(cname = "git_tree_entry_type")]
			get;
		}
		/**
		 * Compare two tree entries
		 *
		 * @param that second tree entry
		 * @return <0 if this is before that, 0 if this == that, >0 if this is after that
		 */
		[CCode(cname = "git_tree_entry_cmp")]
		public int cmp(TreeEntry that);

		/**
		 * Create a new tree builder.
		 *
		 * The tree builder can be used to create or modify trees in memory and
		 * write them as tree objects to the database.
		 *
		 * The tree builder will be initialized with the entries of the given tree.
		 *
		 * @param builder where to store the tree builder
		 */
		[CCode(cname = "git_treebuilder_create", instance_pos = -1)]
		public Error create_builder(out TreeBuilder builder);
		/**
		 * Create a copy of a tree entry.
		 */
		[CCode(cname = "git_tree_entry_dup")]
		public TreeEntry dup();
	}

	/**
	 * List of unmerged index entries
	 */
	[CCode(cname = "git_index", has_type_id = false)]
	[Compact]
	public class ReucIndex {
		/**
		 * The count of unmerged entries currently in the index
		 */
		public uint size {
			[CCode(cname = "git_index_reuc_entrycount")]
			get;
		}
		/**
		 * Adds a resolve undo entry for a file based on the given parameters.
		 *
		 * The resolve undo entry contains the OIDs of files that were involved in
		 * a merge conflict after the conflict has been resolved. This allows
		 * conflicts to be re-resolved later.
		 *
		 * If there exists a resolve undo entry for the given path in the index, it
		 * will be removed.
		 *
		 * This method will fail in bare index instances.
		 *
		 * @param path filename to add
		 * @param ancestor_mode mode of the ancestor file
		 * @param ancestor_id oid of the ancestor file
		 * @param our_mode mode of our file
		 * @param our_id oid of our file
		 * @param their_mode mode of their file
		 * @param their_id oid of their file
		 */
		[CCode(cname = "git_index_reuc_add")]
		public Error add(string path, FileMode ancestor_mode, object_id ancestor_id, FileMode our_mode, object_id our_id, FileMode their_mode, object_id their_id);

		/**
		 * Remove all resolve undo entries from the index
		 */
		[CCode(cname = "git_index_reuc_clear")]
		public void clear();

		/**
		 * Finds the resolve undo entry that points to the given path in the Git
		 * index.
		 *
		 * @param path path to search
		 * @return an index >= 0 if found, -1 otherwise
		 */
		[CCode(cname = "git_index_reuc_find")]
		public Error find(string path);

		/**
		 * Get an unmerged entry from the index.
		 *
		 * @param n the position of the entry
		 * @return a pointer to the unmerged entry; null if out of bounds
		 */
		[CCode(cname = "git_index_reuc_get_byindex")]
		public unowned index_reuc_entry? get(uint n);

		/**
		 * Get an unmerged entry from the index.
		 *
		 * @param path path to search
		 * @return the unmerged entry; null if not found
		 */
		[CCode(cname = "git_index_reuc_get_bypath")]
		public unowned index_reuc_entry? get_by_path(string path);

		/**
		 * Remove an resolve undo entry from the index
		 *
		 * @param n position of the resolve undo entry to remove
		 */
		[CCode(cname = "git_index_reuc_remove")]
		public Error remove(size_t n);
	}
	[CCode(cname = "git_checkout_opts", has_type_id = false, default_value = "GIT_CHECKOUT_OPTS_INIT")]
	public struct checkout_opts {
		[CCode(cname = "GIT_CHECKOUT_OPTS_VERSION")]
		public const uint VERSION;

		public uint version;
		public unowned CheckoutStategy checkout_strategy;
		public bool disable_filters;
		/**
		 * Directory mode.
		 *
		 * If set to 0, the default is 0755 used.
		 */
		public int dir_mode;
		/**
		 * File mode.
		 *
		 * If set to 0, the default is 0644 is used.
		 */
		public int file_mode;
		/**
		 * File open(3) flags.
		 *
		 * If set to 0, the default is O_CREAT | O_TRUNC | O_WRONLY is used.
		 */
		public int file_open_flags;
		public CheckoutNotify notify_flags;
		[CCode(cname = "notify_cb", delegate_target_cname = "notify_payload")]
		public unowned CheckoutNotify? notify;

		/**
		 * Notify the consumer of checkout progress.
		 */
		[CCode(cname = "progress_cb", delegate_target_cname = "progress_payload")]
		public unowned Progress? progress;

		/**
		 * When not null, arrays of fnmatch pattern specifying which paths should be taken into account
		 */
		public string_array paths;
		/**
		 * Expected content of workdir, defaults to HEAD
		 */
		public unowned Tree? baseline;
	}

	[CCode(cname = "git_config_entry", has_type_id = false)]
	public struct config_entry{
		public string name;
		public string @value;
		public ConfigLevel level;
	}

	/**
	 * Clone options structure
	 */
	[CCode(cname = "git_clone_options", has_type_id = false, default_value = "GIT_CLONE_OPTIONS_INIT")]
	public struct clone_opts {
		[CCode(cname = "GIT_CLONE_OPTIONS_VERSION")]
		public const uint VERSION;
		public uint version;
		public checkout_opts checkout_opts;
		/**
		 * False to create a standard repo, true for a bare repo.
		 */
		public bool bare;
		[CCode(cname = "fetch_progress_cb", delegate_target_cname = "fetch_progress_payload")]
		public unowned TransferProgress? fetch_progress;

		/**
		 * The name given to the "origin" remote.
		 *
		 * The default is "origin".
		 */
		public string? remote_name;
		/**
		 * The URL to be used for pushing.
		 *
		 * If unset, the fetch URL will be used.
		 */
		public string? pushurl;
		/**
		 * The fetch specification to be used for fetching.
		 *
		 * If unset, "+refs/heads/ *:refs/remotes/<remote_name>/ *"
		 */
		public string? fetch_spec;
		/**
		 * The fetch specification to be used for pushing.
		 *
		 * If unset, the same spec as for fetching.
		 */
		public string? push_spec;
		/**
		 * Callback to be used if credentials are required during the initial
		 * fetch.
		 */
		[CCode(cname = "git_cred_acquire_cb", delegate_target_cname = "cred_acquire_payload")]
		public unowned CredAcquire cred_acquire;
		/**
		 * A custom transport to be used for the initial fetch.
		 *
		 * If unset, the transport autodetected from the URL.
		 */
		public unowned transport? transport;
		/**
		 * May be used to specify custom progress callbacks for the origin remote
		 * before the fetch is initiated.
		 */
		public unowned remote_callbacks? remote_callbacks;
		/**
		 * May be used to specify the autotag setting before the initial fetch.
		 */
		AutoTag remote_autotag;
		/**
		 * Gives the name of the branch to checkout.
		 *
		 * If unset, use the remote's HEAD.
		 */
		public string? checkout_branch;
	}

	[CCode(cname = "git_cvar_map", has_type_id = false)]
	public struct config_var_map {
		public ConfigVar cvar_type;
		public string? str_match;
		public int map_value;
	}
	[CCode(cname = "git_cred")]
	public struct cred {
		public CredTypes credtype;
		public CredFree free;

		/**
		 * Creates a new plain-text username and password credential object.
		 *
		 * @param username The username of the credential.
		 * @param password The password of the credential.
		 */
		[CCode(cname = "git_cred_userpass_plaintext_new")]
		public static Error create_userpass_plaintext(out cred? cred, string username, string password);
	}
	[CCode(cname = "git_cred_userpass_payload", has_type_id = false)]
	public struct cred_userpass {
		public string username;
		public string password;
		/**
		 * Method usable as {@link CredAcquire}.
		 *
		 * This calls {@link cred.create_userpass_plaintext} unless the protocol
		 * has not specified {@link CredTypes.USERPASS_PLAINTEXT} as an allowed
		 * type.
		 *
		 * @param cred The newly created credential object.
		 * @param url The resource for which we are demanding a credential.
		 * @param username_from_url The username that was embedded in a "user@host"
		 * remote url, or null if not included.
		 */
		[CCode(cname = "git_cred_userpass", instance_pos = -1)]
		public Error acquire(out cred? cred, string url, string? username_from_url, CredTypes allowed_types);
	}

	/**
	 * Description of changes to one entry.
	 *
	 * When iterating over a diff list object, this will be passed to most
	 * callback functions and you can use the contents to understand exactly what
	 * has changed.
	 *
	 * The {@link diff_delta.old_file} repesents the "from" side of the diff and
	 * the {@link diff_delta.new_file} repesents to "to" side of the diff. What
	 * those means depend on the function that was used to generate the diff and
	 * will be documented below. You can also use the {@link DiffFlags.REVERSE}
	 * flag to flip it around.
	 *
	 * Although the two sides of the delta are named "old_file" and "new_file",
	 * they actually may correspond to entries that represent a file, a symbolic
	 * link, a submodule commit id, or even a tree (if you are tracking type
	 * changes or ignored/untracked directories).
	 *
	 * Under some circumstances, in the name of efficiency, not all fields will
	 * be filled in, but we generally try to fill in as much as possible.
	 */
	[CCode(cname = "git_diff_delta", has_type_id = false)]
	public struct diff_delta {
		public diff_file old_file;
		public diff_file new_file;
		public DeltaType status;
		/**
		 * For RENAMED and COPIED, value 0-100
		 */
		public uint similarity;
		public DiffFlag flags;
	}

	/**
	 * Description of one side of a diff.
	 * Although this is called a "file", it may actually represent a file, a
	 * symbolic link, a submodule commit id, or even a tree (although that only
	 * if you are tracking type changes or ignored/untracked directories).
	 *

	 */
	[CCode(cname = "git_diff_file", has_type_id = false)]
	public struct diff_file {
		/**
		 * The object id.
		 *
		 * If the entry represents an absent side of a diff (e.g., the {@link diff_delta.old_file}
		 * of a {@link DeltaType.ADDED} delta), then the oid will be zeroes.
		 */
		[CCode(cname = "oid")]
		public object_id id;
		/**
		 * The path to the entry relative to the working directory of the
		 * repository.
		 */
		public string path;
		public FileMode mode;
		/**
		 * The size of the entry in bytes.
		 */
		public int size;
		public DiffFlag flags;
	}

	/**
	 * Structure describing options about how the diff should be executed.
	 *
	 * Setting all values of the structure to zero will yield the default
	 * values. Similarly, passing NULL for the options structure will
	 * give the defaults. The default values are marked below.
	 *
	 * Most of the parameters here are not actually supported at this time.
	 */
	[CCode(cname = "git_diff_options", has_type_id = false, default_value = "GIT_DIFF_OPTIONS_INIT")]
	public struct diff_options {
		[CCode(cname = "GIT_DIFF_OPTIONS_VERSION")]
		public const uint VERSION;
		/**
		 * Version for the struct
		 */
		public uint version;
		public DiffFlags flags;
		/**
		 * Number of lines of context to show around diffs
		 */
		public uint16 context_lines;
		/**
		 * Min lines between diff hunks to merge them
		 */
		public uint16 interhunk_lines;
		/**
		 * "Directory" to prefix to old file names (default "a")
		 */
		public string? old_prefix;
		/**
		 * "Directory" to prefix to new file names (default "b")
		 */
		public string? new_prefix;
		/**
		 * Array of paths / patterns to constrain diff
		 *
		 * Defaults to all paths
		 */
		public string_array pathspec;
		/**
		 * Maximum blob size to diff, above this treated as binary
		 *
		 * Defaults to 512 MB.
		 */
		public uint64 max_size;
	}

	/**
	 * Structure describing a hunk of a diff.
	 */
	[CCode(cname = "git_diff_range", has_type_id = false)]
	public struct diff_range {
		public int old_start;
		public int old_lines;
		public int new_start;
		public int new_lines;
	}

	[CCode(cname = "git_diff_find_options", has_type_id = false, default_value = "GIT_DIFF_FIND_OPTIONS_INIT ")]
	public struct find_options {
		[CCode(cname = "GIT_DIFF_FIND_OPTIONS_VERSION")]
		public const uint VERSION;
		public uint version;
		public DiffFind flags;
		/**
		 * Similarity to consider a file renamed (default 50)
		 */
		public uint rename_threshold;
		/**
		 * Similarity of modified to be eligible rename source (default 50)
		 */
		public uint rename_from_rewrite_threshold;
		/**
		 * Similarity to consider a file a copy (default 50)
		 */
		public uint copy_threshold;
		/**
		 * Similarity to split modify into delete/add pair (default 60)
		 */
		public uint break_rewrite_threshold;
		/**
		 * Maximum similarity sources to examine (e.g., diff's '''-l''' option or
		 * the '''diff.renameLimit''' config) (default 200)
		 */
		public uint target_limit;
	}

	/**
	 * Time used in a index entry
	 */
	[CCode(cname = "git_index_time", has_type_id = false)]
	public struct index_time {
		public int64 seconds;
		public uint nanoseconds;
	}

	/**
	 * A resolve undo entry in the index.
	 */
	[CCode(cname = "git_index_reuc_entry", has_type_id = false)]
	public struct index_reuc_entry {
		uint mode[3];
		[CCode(cname = "oid")]
		public object_id id[3];
		public string path;
	}

	/**
	 * Extended options structure for {@link Repository.init_ext}.
	 *
	 * This contains extra options that enable additional initialization
	 * features.
	 */
	[CCode(cname = "git_repository_init_options", has_type_id = false, default_value = "GIT_REPOSITORY_INIT_OPTIONS_INIT")]
	public struct init_options {
		/**
		 * Use permissions configured by umask - the default.
		 */
		[CCode(cname = "GIT_REPOSITORY_INIT_SHARED_UMASK")]
		public const uint32 MODE_SHARED_UMASK;
		/**
		 * Use '''--shared=group''' behavior, chmod'ing the new repo to be group
		 * writable and "g+sx" for sticky group assignment.
		 */
		[CCode(cname = "GIT_REPOSITORY_INIT_SHARED_GROUP")]
		public const uint32 MODE_SHARED_GROUP;
		/**
		 * Use '''--shared=all''' behavior, adding world readability.
		 */
		[CCode(cname = "GIT_REPOSITORY_INIT_SHARED_ALL")]
		public const uint32 MODE_SHARED_ALL;
		[CCode(cname = "GIT_REPOSITORY_INIT_OPTIONS_VERSION")]
		public const uint VERSION;
		public uint version;
		public InitFlag flags;
		/**
		 * The UNIX file mode.
		 *
		 * The standard values are {@link MODE_SHARED_UMASK},
		 * {@link MODE_SHARED_GROUP}, or {@link MODE_SHARED_ALL}, but a custom
		 * value may be used instead.
		*/
		public uint32 mode;
		/**
		 * The path to the working dir or null for default (i.e., the repoistory
		 * path's parent on non-bare repos).
		 *
		 * If this is relative path, it will be evaluated relative to the
		 * repository path.
		 *
		 * If this is not the natural working directory, a .git gitlink file will
		 * be created here linking to the repoitory path.
		 */
		public string? workdir_path;
		/**
		 * If set, this will be used to initialize the '''description''' file in
		 * the repository, instead of using the template content.
		 */
		public string? description;
		/**
		 * When {@link InitFlag.EXTERNAL_TEMPLATE} is set, this contains the path
		 * to use for the template directory.
		 *
		 * If this is null, the config or default directory options will be used
		 * instead.
		 */
		public string? template_path;
		/**
		 * The name of the head to point HEAD at. If null, then this will be
		 * treated as '''master''' and the HEAD ref will be set to
		 * '''refs/heads/master'''. If this begins with '''refs/''' it will be
		 * used verbatim; otherwise '''refs/heads/''' will be prefixed.
		 */
		public string? initial_head;
		/**
		 * If this is non-null, then after the rest of the repository
		 * initialization is completed, an '''origin''' remote will be added
		 * pointing to this URL.
		 */
		public string? origin_url;
	}

	/**
	 * Unique identity of any object (commit, tree, blob, tag).
	 */
	[CCode(cname = "git_oid", has_type_id = false)]
	public struct object_id {
		/**
		 * Raw binary formatted id
		 */
		uint8 id[20];

		[CCode(cname = "GIT_OID_HEX_ZERO")]
		public const string HEX_ZERO;

		/**
		 * Size (in bytes) of a raw/binary id
		 */
		[CCode(cname = "GIT_OID_RAWSZ")]
		public const int RAW_SIZE;

		/**
		 * Size (in bytes) of a hex formatted id
		 */
		[CCode(cname = "GIT_OID_HEXSZ")]
		public const int HEX_SIZE;

		/**
		 * Minimum length (in number of hex characters,
		 * (i.e., packets of 4 bits) of an id prefix
		 */
		[CCode(cname = "GIT_OID_MINPREFIXLEN")]
		public const int MIN_PREFIX_LENGTH;

		/**
		 * Parse a hex formatted null-terminated string.
		 *
		 * @param id id structure the result is written into.
		 * @param str input hex string; must be at least 4 characters long.
		 */
		[CCode(cname = "git_oid_fromstrp")]
		public static Error from_string(out object_id id, string str);

		/**
		 * Parse a hex formatted object id
		 *
		 * @param id id structure the result is written into.
		 * @param str input hex string; must be pointing at the start of the hex
		 * sequence and have at least the number of bytes needed for an id encoded
		 * in hex (40 bytes).
		 * @return {@link Error.OK} if valid, {@link Error.NOTID} on failure.
		 */
		[CCode(cname = "git_oid_fromstr")]
		public static Error from_string_exact(out object_id id, string str);

		/**
		 * Parse N characters of a hex formatted object id
		 *
		 * If N is odd, N-1 characters will be parsed instead.
		 * The remaining space in the git_oid will be set to zero.
		 *
		 * @param id id structure the result is written into.
		 * @param data input hex string
		 * @return {@link Error.OK} if valid.
		 */
		[CCode(cname = "git_oid_fromstrn")]
		public static Error from_array(out object_id id, [CCode(array_length_type = "size_t")] uint8[] data);

		/**
		 * Copy an already raw id
		 */
		[CCode(cname = "git_oid_fromraw")]
		public static void from_raw(out object_id id, [CCode(array_length = false)] uint8[] raw);

		/**
		 * Format an id into a hex string.
		 *
		 * @param str output hex string; must be pointing at the start of the hex
		 * sequence and have at least the number of bytes needed for an id encoded
		 * in hex (40 bytes). Only the id digits are written; a nul terminator must
		 * be added by the caller if it is required.
		 */
		[CCode(cname = "git_oid_fmt", instance_pos = -1)]
		public void to_buffer([CCode(array_length = false)] char[] str);

		/**
		 * Format an id into a loose-object path string.
		 *
		 * The resulting string is "aa/...", where "aa" is the first two
		 * hex digitis of the id and "..." is the remaining 38 digits.
		 *
		 * @param str output hex string; must be pointing at the start of the hex
		 * sequence and have at least the number of bytes needed for an oid encoded
		 * in hex (41 bytes). Only the id digits are written; a nul terminator
		 * must be added by the caller if it is required.
		 */
		[CCode(cname = "git_oid_pathfmt", instance_pos = -1)]
		public void to_path([CCode(array_length = false)] char[] str);

		/**
		 * Format an id into a string.
		 *
		 * @return the string; null if memory is exhausted.
		 */
		[CCode(cname = "git_oid_allocfmt")]
		public string? to_string();

		/**
		 * Format an id into a buffer as a hex format string.
		 *
		 * If the buffer is smaller than {@link HEX_SIZE}+1, then the resulting
		 * id string will be truncated to data.length-1 characters. If there are
		 * any input parameter errors, then a pointer to an empty string is returned,
		 * so that the return value can always be printed.
		 *
		 * @param buffer the buffer into which the id string is output.
		 * @return the out buffer pointer, assuming no input parameter errors,
		 * otherwise a pointer to an empty string.
		 */
		[CCode(cname = "git_oid_tostr", instance_pos = -1)]
		public unowned string to_string_buffer([CCode(array_length_type = "size_t")] char[] buffer);

		/**
		 * Copy an id from one structure to another.
		 *
		 * @param dest id structure the result is written into.
		 * @param src id structure to copy from.
		 */
		[CCode(cname = "git_oid_cpy")]
		public static void copy(out object_id dest, object_id src);

		/**
		 * Copy an id from one structure to another.
		 *
		 * @param dest id structure the result is written into.
		 */
		[CCode(cname = "git_oid_cpy", instance_pos = -1)]
		public void copy_to(out object_id dest);

		/**
		 * Compare two id structures.
		 *
		 * @param a first id structure.
		 * @param b second id structure.
		 * @return <0, 0, >0 if a < b, a == b, a > b.
		 */
		[CCode(cname = "git_oid_cmp")]
		public static int compare(object_id a, object_id b);

		/**
		 * Compare two id structures.
		 *
		 * @param b second id structure.
		 * @return <0, 0, >0 if a < b, a == b, a > b.
		 */
		[CCode(cname = "git_oid_cmp")]
		public int compare_to(object_id b);

		/**
		 * Compare the first //len// hexadecimal characters (packets of 4 bits)
		 * of two id structures.
		 *
		 * @param a first id structure.
		 * @param b second id structure.
		 * @param len the number of hex chars to compare
		 * @return 0 in case of a match
		 */
		[CCode(cname = "git_oid_ncmp")]
		public static int compare_n(object_id a, object_id b, size_t len);

		/**
		 * Compare the first //len// hexadecimal characters (packets of 4 bits)
		 * of two id structures.
		 *
		 * @param b second id structure.
		 * @param len the number of hex chars to compare
		 * @return 0 in case of a match
		 */
		[CCode(cname = "git_oid_ncmp")]
		public int compare_n_to(object_id b, size_t len);

		/**
		 * Check if an oid equals an hex formatted object id.
		 *
		 * @param str input hex string of an object id.
		 * @return {@link Error.OK} in case of a match, {@link Error.ERROR} otherwise.
		 */
		[CCode(cname = "git_oid_streq")]
		public Error compare_string(string str);
		/**
		 * Compare two oid structures for equality
		 *
		 * @param a first id structure.
		 * @param b second id structure.
		 * @return true if equal, false otherwise
		 */
		[CCode(cname = "git_oid_equal")]
		public static bool equal(object_id a, object_id b);
		/**
		 * Compare two oid structures for equality
		 *
		 * @param b second id structure.
		 * @return true if equal, false otherwise
		 */
		[CCode(cname = "git_oid_equal")]
		public bool equal_to(object_id b);

		/**
		 * Determine the id of a buffer containing an object
		 *
		 * The resulting id will the itentifier for the data
		 * buffer as if the data buffer it were to written to the ODB.
		 *
		 * @param id the resulting id.
		 * @param data data to hash
		 * @param type of the data to hash
		 */
		[CCode(cname = "git_odb_hash")]
		public static Error from_data(out object_id id, [CCode(array_length_type = "size_t")] uint8[] data, ObjectType type);

		/**
		 * Read a file from disk and determine the id
		 *
		 * Read the file and compute the id have if it were
		 * written to the database as an object of the given type.
		 * Similar functionality to git's //git hash-object// without
		 * the //-w// flag.
		 *
		 * @param id id structure the result is written into.
		 * @param path file to read and determine object id for
		 * @param type the type of the object that will be hashed
		 */
		[CCode(cname = "git_odb_hashfile")]
		public static Error hashfile(out object_id id, string path, ObjectType type);
		/**
		 * Check is an oid is all zeros.
		 */
		[CCode(cname = "git_oid_iszero")]
		public bool is_zero();

	}
	/**
	 * Controls the behavior of a {@link Push} object.
	 */
	[CCode(cname = "git_push_options", has_type_id = false, default_value = "GIT_PUSH_OPTIONS_INIT")]
	public struct push_options {
		[CCode(cname = "GIT_PUSH_OPTIONS_VERSION")]
		public const uint VERSION;
		public uint version;
		/**
		 * If the transport being used to push to the remote requires the creation
		 * of a pack file, this controls the number of worker threads used by the
		 * packbuilder when creating that pack file to be sent to the remote.
		 *
		 * If set to false, the packbuilder will auto-detect the number of threads
		 * to create. The default value is true.
		 */
		public bool pb_parallelism;
	}
	[CCode(cname = "struct git_refdb_backend", default_value = "GIT_ODB_BACKEND_INIT", has_type_id = false)]
	public struct refdb_backend {
		[CCode(cname = "GIT_ODB_BACKEND_VERSION")]
		public const uint VERSION;
		public uint version;
		public RefDbCompress? compress;
		public RefDbDelete @delete;
		public RefDbExists exists;
		public RefDbForEach @foreach;
		public RefDbForEachGlob? foreach_glob;
		public RefDbFree? free;
		public RefDbLookup lookup;
		public RefDbWrite write;
		/**
		 * Constructors for default refdb backend.
		 */
		[CCode(cname = "git_refdb_backend_fs")]
		public static Error create_backend_fs(out refdb_backend? backend, Repository repo, RefDb refdb);
	}
	/**
	 * Reference specification (i.e., some kind of local or remote branch)
	 */
	[CCode(cname = "git_refspec", has_type_id = false, destroy_function = "")]
	public struct ref_spec {
		/**
		 * The destination specifier
		 */
		public string destination {
			[CCode(cname = "git_refspec_dst")]
			get;
		}
		/**
		 * The force update setting
		 */
		public bool is_forced {
			[CCode(cname = "git_refspec_force")]
			get;
		}

		/**
		 * The source specifier
		 */
		public string source {
			[CCode(cname = "git_refspec_src")]
			get;
		}

		/**
		 * Check if a refspec's source descriptor matches a reference name
		 *
		 * @param refname the name of the reference to check
		 */
		[CCode(cname = "git_refspec_src_matches")]
		public bool matches_source(string refname);

		/**
		 * Check if a refspec's destination descriptor matches a reference
		 *
		 * @param refname the name of the reference to check
		 */
		[CCode(cname = "git_refspec_dst_matches")]
		public bool matches_destination(string refname);

		/**
		 * Transform a target reference to its source reference following the refspec's rules
		 *
		 * @param refname where to store the source reference name
		 * @param name the name of the reference to transform
		 */
		[CCode(cname = "git_refspec_rtransform", instance_pos = 1.2)]
		public Error rtransform([CCode(array_length_type = "size_t")] uint8[] refname, string name);

		/**
		 * Transform a reference to its target following the refspec's rules
		 *
		 * @param buffer where to store the target name
		 * @param name the name of the reference to transform
		 * @return {@link Error.OK}, {@link Error.SHORTBUFFER} or another error
		 */
		[CCode(cname = "git_refspec_transform", instance_pos = 1.3)]
		public Error transform([CCode(array_length_type = "size_t")] char[] buffer, string name);
	}


	/**
	 * Remote head description, given out on //ls// calls.
	 */
	[CCode(cname = "struct git_remote_head", has_type_id = false)]
	public struct remote_head {
		public bool local;
		[CCode(cname = "oid")]
		public object_id id;
		[CCode(cname = "loid")]
		public object_id l_id;
		public unowned string name;
	}

	[CCode(cname = "git_remote_callbacks", simple_generics = true, default_value = "GIT_REMOTE_CALLBACKS_INIT ")]
	public struct remote_callbacks<T> {
		[CCode(cname = "GIT_REMOTE_CALLBACKS_VERSION")]
		public const uint VERSION;

		public uint version;
		public RemoteProgress<T>? progress;
		public RemoteCompletion<T>? completion;
		public RemoteUpdateTips<T>? update_tips;

		[CCode(simple_generics = true)]
		public T payload;
	}
	/**
	 * The smart transport knows how to speak the git protocol, but it has no
	 * knowledge of how to establish a connection between it and another
	 * endpoint, or how to move data back and forth.
	 *
	 * For this, a subtransport interface is declared, and the smart transport
	 * delegates this work to the subtransports. Three subtransports are
	 * implemented: git, http, and winhttp. (The http and winhttp transports each
	 * implement both http and https.)
	 *
	 * Subtransports can either be persistent or stateless (request/response).
	 * The smart transport handles the differences in its own logic.
	 */
	[CCode(cname = "git_smart_subtransport")]
	public struct smart_subtransport {
		public SubTransportAction action;

		/**
		 * Subtransports are guaranteed a call to {@link close} between calls to
		 * {@link action}, except for the following two natural progressions of
		 * actions against a constant URL.
		 *
		 * 1. {@link SmartService.UPLOADPACK_LS} → {@link SmartService.UPLOADPACK}
		 * 2. {@link SmartService.RECEIVEPACK_LS} → {@link SmartService.RECEIVEPACK}
		 */
		public SubTransportClose close;
		public SubTransportFree free;
	}
	[CCode(cname = "git_smart_subtransport_definition")]
	public struct smart_subtransport_definition {
		/**
		 * Create an instance of the smart transport.
		 *
		 * @param owner The {@link Remote} which will own this transport
		 */
		[CCode(cname = "git_transport_smart", instance_pos = -1)]
		public Error create_transport(out transport? transport, Remote owner);

		/**
		 * The function to use to create the subtransport
		 */
		public CreateSubTransport callback;

		/**
		 * Is the protocol is stateless.
		 *
		 * For example, http:// is stateless, but git:// is not.
		 */
		[CCode(cname = "rpc")]
		public bool rpc;
	}
	/**
	 * A stream used by the smart transport to read and write data from a
	 * subtransport
	 */
	[CCode(cname = "git_smart_subtransport_stream")]
	public struct smart_subtransport_stream {
		/**
		 * The owning subtransport
		 */
		public unowned smart_subtransport? subtransport;
		public SubTransportStreamRead read;
		public SubTransportStreamWrite write;
		public SubTransportStreamFree free;
	}
	[CCode(cname = "git_status_options", has_type_id = false, default_value = "GIT_STATUS_OPTIONS_INIT")]
	public struct status_options {
		[CCode(cname = "GIT_STATUS_OPTIONS_VERSION")]
		public const uint VERSION;

		public uint version;
		StatusShow show;
		StatusControl flags;
		/**
		 * The path patterns to match (using fnmatch-style matching), or just an
		 * array of paths to match exactly if {@link DiffFlags.DISABLE_PATHSPEC_MATCH}
		 * is specified in the flags.
		 */
		string_array pathspec;
	}

	/**
	 * Collection of strings
	 */
	[CCode(cname = "git_strarray", destroy_function = "git_strarray_free", has_type_id = false)]
	public struct string_array {
		[CCode(array_length_cname = "count", array_length_type = "size_t")]
		string[]? strings;
		[CCode(cname = "git_strarray_copy", instance_pos = -1)]
		public Error copy(out string_array target);
	}

	/**
	 * Time in a signature
	 */
	[CCode(cname = "git_time", has_type_id = false)]
	public struct time {
		/**
		 * time in seconds from epoch
		 */
		int64 time;
		/**
		 * timezone offset, in minutes
		 */
		int offset;
	}
	[CCode(cname = "git_transfer_progress", has_type_id = false)]
	public struct transfer_progress {
		public uint total_objects;
		public uint indexed_objects;
		public uint received_objects;
		public size_t received_bytes;
	}
	[CCode(cname = "git_transport", has_type_id = false, default_value = "GIT_TRANSPORT_INIT ")]
	public struct transport {
		[CCode(cname = "GIT_TRANSPORT_VERSION")]
		public const uint VERSION;
		public uint version;
		/**
		 * Set progress and error callbacks
		 */
		public TransportSetCallbacks set_callbacks;
		/**
		 * Connect the transport to the remote repository, using the given
		 * direction.
		 */
		public TransportConnect connect;
		/**
		 * This function may be called after a successful call to {@link connect}.
		 *
		 * The provided callback is invoked for each ref discovered on the remote
		 * end.
		 */
		public TransportList ls;
		/**
		 * Executes the push whose context is in a {@link Push} object.
		 */
		public TransportPush push;
		/**
		 * The function performs a negotiation to calculate the wants list for the
		 * fetch.
		 *
		 * This function may be called after a successful call to {@link connect},
		 * when the direction is FETCH.
		 */
		public TransportNegotiatFetch negotiate_fetch;
		/**
		 * This function retrieves the pack file for the fetch from the remote end.
		 *
		 * This function may be called after a successful call to
		 * {@link negotiate_fetch}, when the direction is FETCH.
		 */
		public TransportDownloadPack download_pack;
		/**
		 * Checks to see if the transport is connected
		 */
		public TransportIsConnected is_connected;
		/**
		 * Reads the flags value previously passed into {@link connect}
		 */
		public TransportReadFlags read_flags;
		/**
		 * Cancels any outstanding transport operation
		 */
		public TransportCancel cancel;
		/**
		 * This function is the reverse of {@link connect} – it terminates the
		 * connection to the remote end.
		 */
		public TransportClose close;
		/**
		 * Frees/destructs the transport object.
		 */
		public TransportFree free;

		/**
		 * Function to use to create a transport from a URL.
		 *
		 * The transport database is scanned to find a transport that implements
		 * the scheme of the URI (e.g., git:// or http://) and a transport object
		 * is returned to the caller.
		 *
		 * @param owner The {@link Remote} which will own this transport
		 * @param url The URL to connect to
		 */
		[CCode(cname = "git_transport_new")]
		public static Error create(out transport? transport, Remote owner, string url);

		/**
		 * Create an instance of the dummy transport.
		 *
		 * @param owner The {@link Remote} which will own this transport
		 * @param payload You must pass null for this parameter.
		 */
		[CCode(cname = "git_transport_dummy")]
		public static Error create_dummy(out transport? transport, Remote owner, void* payload = null);
		/**
		 * Create an instance of the local transport.
		 *
		 * @param owner The {@link Remote} which will own this transport
		 * @param payload You must pass null for this parameter.
		 */
		[CCode(cname = "git_transport_local")]
		public static Error create_local(out transport? transport, Remote owner, void* payload = null);

		/**
		 * Create an instance of the http subtransport.
		 *
		 * This subtransport also supports https. On Win32, this subtransport may
		 * be implemented using the WinHTTP library.
		 */
		[CCode(cname = "git_smart_subtransport_http", instance_pos = -1)]
		public Error create_http_subtransport(out smart_subtransport? subtransport);

		/**
		 * Create an instance of the git subtransport.
		 */
		[CCode(cname = "git_smart_subtransport_git", instance_pos = -1)]
		public Error create_git_subtransport(out smart_subtransport? subtransport);
	}

	/**
	 * Default port for git: protocol.
	 */
	[CCode(cname = "GIT_DEFAULT_PORT")]
	public const string DEFAULT_PORT;

	/**
	 * The separator used in path list strings.
	 *
	 * For instance, in the //$PATH// environment variable). A semi-colon ";"
	 * is used on Windows, and a colon ":" for all other systems.
	 */
	[CCode(cname = "GIT_PATH_LIST_SEPARATOR")]
	public const char PATH_LIST_SEPARATOR;

	/**
	 * The maximum length of a git valid git path.
	 */
	[CCode(cname = "GIT_PATH_MAX")]
	public const int PATH_MAX;

	[CCode(cname = "uint32_t", cprefix = "GIT_ATTR_CHECK_", has_type_id = false)]
	[Flags]
	public enum AttrCheck {
		/**
		 * Reading values from index and working directory.
		 *
		 * When checking attributes, it is possible to check attribute files
		 * in both the working directory (if there is one) and the index (if
		 * there is one). You can explicitly choose where to check and in
		 * which order using the following flags.
		 *
		 * Core git usually checks the working directory then the index,
		 * except during a checkout when it checks the index first. It will
		 * use index only for creating archives or for a bare repo (if an
		 * index has been specified for the bare repo).
		 */
		FILE_THEN_INDEX,
		/**
		 * @see FILE_THEN_INDEX
		 */
		INDEX_THEN_FILE,
		/**
		 * @see FILE_THEN_INDEX
		 */
		INDEX_ONLY,
		/**
		 * Using the system attributes file.
		 *
		 * Normally, attribute checks include looking in the /etc (or system
		 * equivalent) directory for a `gitattributes` file. Passing this
		 * flag will cause attribute checks to ignore that file.
		 */
		NO_SYSTEM
	}

	/**
	 * States for a file in the index
	 */
	[CCode(cname = "int", cprefix = "GIT_IDXENTRY_", has_type_id = false)]
	[Flags]
	public enum Attributes {
		EXTENDED,
		VALID,
		UPDATE,
		REMOVE,
		UPTODATE,
		ADDED,
		HASHED,
		UNHASHED,
		WT_REMOVE,
		CONFLICTED,
		UNPACKED,
		NEW_SKIP_WORKTREE,
		INTENT_TO_ADD,
		SKIP_WORKTREE,
		EXTENDED2,
		EXTENDED_FLAGS
	}
	[CCode(cname = "git_remote_autotag_option_t", cprefix = "GIT_REMOTE_DOWNLOAD_TAGS_", has_type_id = false)]
	public enum AutoTag {
		UNSET,
		NONE,
		AUTO,
		ALL
	}

	/**
	 * Basic type of any Git branch.
	 */
	[CCode(cname = "git_branch_t", cprefix = "GIT_BRANCH_", has_type_id = false)]
	[Flags]
	public enum BranchType {
		LOCAL,
		REMOTE
	}
	/**
	 * Combinations of these values describe the capabilities of libgit2.
	 */
	[CCode(cname = "int", cprefix = "GIT_CAP_", has_type_id = false)]
	public enum Capabilities {
		/**
		 * Libgit2 was compiled with thread support.
		 *
		 * Note that thread support is still to be seen as a 'work in progress'.
		 */
		THREADS,
		/**
		 * Libgit2 supports the https protocol.
		 *
		 * This requires the OpenSSL library to be found when compiling libgit2.
		 */
		HTTPS;
		/**
		 * Query compile time options for libgit2.
		 */
		[CCode(cname = "git_libgit2_capabilities")]
		public static Capabilities get();
	}
	/**
	 * Options for which cases to invoke notification callback.
	 */
	[CCode(cname = "git_checkout_notify_t", has_type_id = false, cprefix = "GIT_CHECKOUT_NOTIFY_")]
	[Flags]
	public enum CheckoutNotify {
		NONE,
		/**
		 * Invokes callback on conflicting paths.
		 */
		CONFLICT,
		/**
		 * Invokes callback to notify about "dirty" files, i.e. those that do not
		 * need an update but no longer match the baseline.  Core git displays
		 * these files when checkout runs, but won't stop the checkout.
		 */
		DIRTY,
		/**
		 * Invokes callback to notify for any changed file.
		 */
		UPDATED,
		/**
		 * Invokes callback to notify about untracked files.
		 */
		UNTRACKED,
		/**
		 * Invokes callback to notify about ignored files.
		 */
		IGNORED
	}

	/**
	 * Control what checkout does with files
	 *
	 * No flags does a "dry run" where no files will be modified.
	 *
	 * Checkout groups the working directory content into 3 classes of files: (1)
	 * files that don't need a change, and files that do need a change that
	 * either (2) we are allowed to modifed or (3) we are not. The flags you
	 * pass in will decide which files we are allowed to modify.
	 *
	 * By default, checkout is not allowed to modify any files. Anything needing
	 * a change would be considered a conflict.
	 *
	 * If any files need update but are disallowed by the strategy, normally
	 * checkout calls the conflict callback (if given) and then aborts.
	 *
	 * Any unmerged entries in the index are automatically considered conflicts.
	 */
	[CCode(cname = "git_checkout_strategy_t", has_type_id = false, cprefix = "GIT_CHECKOUT_")]
	[Flags]
	public enum CheckoutStategy {
		/**
		 * Dry run, no actual updates
		 */
		NONE,
		/**
		 * Allow safe updates that cannot overwrite uncommited data
		 */
		SAFE,
		/**
		 * Allow safe updates plus creation of missing files
		 */
		SAFE_CREATE,
		/**
		 * Allow all updates to force working directory to look like index
		 */
		FORCE,
		/**
		 * Allow checkout to make safe updates even if conflicts are found
		 *
		 * It is okay to update the files that are allowed by the strategy even if
		 * there are conflicts. The conflict callbacks are still made, but
		 * non-conflicting files will be updated.
		 */
		ALLOW_CONFLICTS,
		/**
		 * Remove untracked files not in index (that are not ignored)
		 */
		REMOVE_UNTRACKED,
		/**
		 * Remove ignored files not in index
		 */
		REMOVE_IGNORED,
		/**
		 * Only update existing files, don't create new ones
		 */
		UPDATE_ONLY,
		/**
		 * Normally checkout updates index entries as it goes; this stops that
		 */
		DONT_UPDATE_INDEX,
		/**
		 * Don't refresh index/config/etc before doing checkout
		 */
		NO_REFRESH,
		/**
		 * Treat pathspec as simple list of exact match file paths
		 */
		DISABLE_PATHSPEC_MATCH,
		/**
		 * Allow checkout to skip unmerged files (NOT IMPLEMENTED)
		 */
		SKIP_UNMERGED,
		USE_OURS,
		/**
		 * For unmerged files, checkout stage 3 from index (NOT IMPLEMENTED)
		 */
		USE_THEIRS,
		/**
		 * Recursively checkout submodules with same options (NOT IMPLEMENTED)
		 */
		UPDATE_SUBMODULES,
		/**
		 * Recursively checkout submodules if HEAD moved in super repo (NOT IMPLEMENTED)
		 */
		UPDATE_SUBMODULES_IF_CHANGED
	}

	/**
	 * Priority level of a config file.
	 *
	 * These priority levels correspond to the natural escalation logic (from
	 * higher to lower) when searching for config entries in git.git.
	 */
	[CCode(cname = "int", cprefix = "GIT_CONFIG_LEVEL_", has_type_id = false)]
	public enum ConfigLevel {
		/**
		 * System-wide configuration file.
		 */
		SYSTEM,
		/**
		 * XDG compatible configuration file: '''.config/git/config'''
		 */
		XDG,
		/**
		 * User-specific configuration file, also called global configuration file.
		 */
		GLOBAL,
		/**
		 * Repository specific configuration file.
		 */
		LOCAL,
		/**
		 * Represents the highest level of a config file.
		 */
		LEVEL,
	}

	[CCode(cname = "git_cvar_t", cprefix = "GIT_CVAR_", has_type_id = false)]
	public enum ConfigVar {
		FALSE,
		TRUE,
		INT32,
		STRING
	}

	[CCode(cname = "git_credtype_t", cprefix = "GIT_CREDTYPE_", has_type_id = false)]
	[Flags]
	public enum CredTypes {
		USERPASS_PLAINTEXT
	}

	/**
	 * What type of change is described?
	 */
	[CCode(cname = "git_delta_t", cprefix = "GIT_DELTA_", has_type_id = false)]
	public enum DeltaType {
		/**
		 * Use in queries to include all delta types.
		 */
		[CCode(cname = "(-1)")]
		ALL,
		/**
		 * No changes
		 */
		UNMODIFIED,
		/**
		 * Entry does not exist in old version
		 */
		ADDED,
		/**
		 * Entry does not exist in new version
		 */
		DELETED,
		/**
		 * Entry content changed between old and new
		 */
		MODIFIED,
		/**
		 * Entry was renamed between old and new
		 */
		RENAMED,
		/**
		 * Entry was copied from another old entry
		 */
		COPIED,
		/**
		 * Entry is ignored item in workdir
		 */
		IGNORED,
		/**
		 * Entry is untracked item in workdir
		 */
		UNTRACKED,
		/**
		 * Type of entry changed between old and new
		 */
		TYPECHANGE;
		/**
		 * Look up the single character abbreviation for a delta status code.
		 *
		 * When you call {@link DiffList.print_compact} it prints single letter
		 * codes into the output such as 'A' for added, 'D' for deleted, 'M' for
		 * modified, etc. It is sometimes convenient to convert a {@link DeltaType}
		 * value into these letters for your own purposes. This function does just
		 * that. By the way, unmodified will return a space (i.e. ' ').
		 */
		[CCode(cname = "git_diff_status_char")]
		public char to_char();
	}
	/**
	 * Flags that can be set for the file on side of a diff.
	 */
	[CCode(cname = "uint32", cprefix = "GIT_DIFF_FLAG_", has_type_id = false)]
	[Flags]
	public enum DiffFlag {
		/**
		 * File(s) treated as binary data
		 */
		BINARY,
		/**
		 * File(s) treated as text data
		 */
		NOT_BINARY,
		/**
		 * Id value is known correct
		 */
		[CCode(cname = "GIT_DIFF_FLAG_VALID_OID")]
		VALID_OID
	}
	/**
	 * Control the behavior of diff rename/copy detection.
	 */
	[CCode(cname = "unsigned int", cprefix = "GIT_DIFF_FIND_", has_type_id = false)]
	[Flags]
	public enum DiffFind {
		/**
		 * Look for renames?
		 */
		RENAMES,
		/**
		 * Consider old side of modified for renames?
		 */
		RENAMES_FROM_REWRITES,
		/**
		 * Look for copies?
		 */
		COPIES,
		/**
		 * Consider unmodified as copy sources?
		 */
		COPIES_FROM_UNMODIFIED,
		/**
		 * Split large rewrites into delete/add pairs.
		 */
		AND_BREAK_REWRITES,
		/**
		 * Turn on all finding features
		 */
		ALL,
		/**
		 * Measure similarity ignoring leading whitespace (default)
		 */
		IGNORE_LEADING_WHITESPACE,
		/**
		 * Measure similarity ignoring all whitespace
		 */
		IGNORE_WHITESPACE,
		/**
		 * Measure similarity including all data
		 */
		DONT_IGNORE_WHITESPACE
	}

	[CCode(cname = "uint32_t", cprefix = "GIT_DIFF_", has_type_id = false)]
	[Flags]
	public enum DiffFlags {
		/**
		 * Normal diff, the default
		 */
		NORMAL,
		/**
		 * Reverse the sides of the diff
		 */
		REVERSE,
		/**
		 * Treat all files as text, disabling binary attributes & detection
		 */
		FORCE_TEXT,
		/**
		 * Ignore all whitespace
		 */
		IGNORE_WHITESPACE,
		/**
		 * Ignore changes in amount of whitespace
		 */
		IGNORE_WHITESPACE_CHANGE,
		/**
		 * Ignore whitespace at end of line
		 */
		IGNORE_WHITESPACE_EOL,
		/**
		 * Exclude submodules from the diff completely
		 */
		IGNORE_SUBMODULES,
		/**
		 * Use the "patience diff" algorithm (currently unimplemented)
		 */
		PATIENCE,
		/**
		 * Include ignored files in the diff list
		 */
		INCLUDE_IGNORED,
		/**
		 * Include untracked files in the diff list
		 */
		INCLUDE_UNTRACKED,
		/**
		 * Include unmodified files in the diff list
		 */
		INCLUDE_UNMODIFIED,
		/**
		 * Even with the {@link INCLUDE_UNTRACKED} flag, when an untracked
		 * directory is found, only a single entry for the directory is added to
		 * the diff list; with this flag, all files under the directory will be
		 * included, too.
		 */
		RECURSE_UNTRACKED_DIRS,
		/**
		 * If the pathspec is set in the diff options, this flags means to apply it
		 * as an exact match instead of as an fnmatch pattern.
		 */
		DISABLE_PATHSPEC_MATCH,
		/**
		 * Use case insensitive filename comparisons
		 */
		DELTAS_ARE_ICASE,
		/**
		 * When generating patch text, include the content of untracked files
		 */
		INCLUDE_UNTRACKED_CONTENT,
		/**
		 * Disable updating of the binary flag in delta records. This is useful
		 * when iterating over a diff if you don't need hunk and data callbacks and
		 * want to avoid having to load file completely.
		 */
		SKIP_BINARY_CHECK,
		/**
		 * Normally, a type change between files will be converted into a DELETED
		 * record for the old and an ADDED record for the new; this options enabled
		 * the generation of TYPECHANGE delta records.
		 */
		INCLUDE_TYPECHANGE,
		/**
		 * Even with {@link INCLUDE_TYPECHANGE}, blob to tree changes still
		 * generally show as a DELETED blob. This flag tries to correctly label
		 * blob to tree transitions as TYPECHANGE records with the new file's mode
		 * set to tree.
		 *
		 * Note: the tree SHA will not be available.
		 */
		INCLUDE_TYPECHANGE_TREES,
		/**
		 * Ignore file mode changes
		 */
		IGNORE_FILEMODE,
		/**
		 * Even with {@link INCLUDE_IGNORED}, an entire ignored directory will be
		 * marked with only a single entry in the diff list; this flag adds all
		 * files under the directory as IGNORED entries, too.
		 */
		RECURSE_IGNORED_DIRS
	}

	/**
	 * Line origin constants.
	 *
	 * These values describe where a line came from and will be passed to
	 * the {@link DiffLine} when iterating over a diff. There are some
	 * special origin contants at the end that are used for the text
	 * output callbacks to demarcate lines that are actually part of
	 * the file or hunk headers.
	 */
	[CCode(cname = "char", cprefix = "GIT_DIFF_LINE_", has_type_id = false)]
	public enum DiffLineType {
		CONTEXT,
		ADDITION,
		DELETION,
		[Deprecated]
		ADD_EOFNL,
		DEL_EOFNL,
		FILE_HDR,
		HUNK_HDR,
		BINARY;
		[CCode(cname = "")]
		public char to_char();
	}

	/**
	 * Transfer direction in a transport
	 */
	[CCode(cname = "int", cprefix = "GIT_DIR_", has_type_id = false)]
	public enum Direction {
		FETCH, PUSH
	}

	/**
	 * Return codes for many functions.
	 */
	[CCode(cname = "git_error_t", cprefix = "GIT_E", has_type_id = false)]
	public enum Error {
		[CCode(cname = "GIT_OK")]
		OK,
		[CCode(cname = "GIT_ERROR")]
		ERROR,
		/**
		 * Input does not exist in the scope searched
		 */
		NOTFOUND,
		/**
		 * A reference with this name already exists
		 */
		EXISTS,
		/**
		 * The given integer literal is too large to be parsed
		 */
		OVERFLOW,
		/**
		 * The given short {@link object_id} is ambiguous
		 */
		AMBIGUOUS,
		BUFS,
		USER,
		/**
		 * Skip and passthrough the given ODB backend
		 */
		PASSTHROUGH,
		/**
		 * The buffer is too short to satisfy the request
		 */
		SHORTBUFFER,
		/**
		 * The revsion walk is complete.
		 */
		ITEROVER,
		SSL,
		BAREREPO,
		ORPHANEDHEAD,
		UNMERGED,
		NONFASTFORWARD,
		INVALIDSPEC,
		MERGECONFLICT
	}

	[CCode(cname = "git_error_class", cprefix = "GITERR_", has_type_id = false)]
	public enum ErrClass {
		NOMEMORY,
		OS,
		INVALID,
		REFERENCE,
		ZLIB,
		REPOSITORY,
		CONFIG,
		REGEX,
		ODB,
		INDEX,
		OBJECT,
		NET,
		TAG,
		TREE,
		INDEXER,
		SSL,
		SUBMODULE,
		THREAD,
		STASH,
		CHECKOUT,
		FETCHHEAD,
		MERGE;
		/**
		 * Set the error message string for this thread.
		 *
		 * This function is public so that custom ODB backends and the like can
		 * relay an error message through libgit2. Most regular users of libgit2
		 * will never need to call this function -- actually, calling it in most
		 * circumstances (for example, calling from within a callback function)
		 * will just end up having the value overwritten by libgit2 internals.
		 *
		 * This error message is stored in thread-local storage and only applies to
		 * the particular thread that this libgit2 call is made from.
		 *
		 * {@link ErrClass.OS} has a special behavior: we attempt to append the
		 * system default error message for the last OS error that occurred and
		 * then clear the last error. The specific implementation of looking up
		 * and clearing this last OS error will vary by platform.
		 *
		 * @param message The formatted error message to keep
		 */
		[CCode(cname = "giterr_set_str")]
		void raise(string message);
	}
	/**
	 * The UNIX file mode associated with a {@link TreeEntry}.
	 *
	 * Consult the mode_t manual page.
	 */
	[CCode(cname = "unsigned int", cheader_filename = "sys/stat.h", cprefix = "S_I", has_type_id = false)]
	[Flags]
	public enum FileMode {
		/**
		 * This is the mask to isolate only the F modes.
		 */
		FMT,
		/**
		 * A block device
		 */
		FBLK,
		/**
		 * A character device
		 */
		FCHR,
		/**
		 * A directory
		 */
		FDIR,
		/**
		 * A FIFO special
		 */
		FIFO,
		/**
		 * A symbolic link
		 */
		FLNK,
		/**
		 * A regular file
		 */
		FREG,
		/**
		 * A socket
		 */
		FSOCK,
		/**
		 * Read, write, and execute by owner
		 */
		RWXU,
		/**
		 * Read by owner
		 */
		RUSR,
		/**
		 * Write by owner
		 */
		WUSR,
		/**
		 * Execute by owner
		 */
		XUSR,
		/**
		 * Read, write, and execute by group
		 */
		RWXG,
		/**
		 * Read by group
		 */
		RGRP,
		/**
		 * Write by group
		 */
		WGRP,
		/**
		 * Execute by group
		 */
		XGRP,
		/**
		 * Read, write, and execute by others
		 */
		RWXO,
		/**
		 * Read by others
		 */
		ROTH,
		/**
		 * Write by others
		 */
		WOTH,
		/**
		 * Execute by others
		 */
		XOTH,
		/**
		 * Set user-id on execution
		 */
		SUID,
		/**
		 * Set group-id on execution
		 */
		SGID,
		/**
		 * Restricted delition on directories
		 */
		SVTX;
		[CCode(cname = "S_ISBLK")]
		public bool is_block_dev();
		[CCode(cname = "S_ISCHR")]
		public bool is_char_dev();
		[CCode(cname = "S_ISDIR")]
		public bool is_dir();
		[CCode(cname = "S_ISFIFO")]
		public bool is_fifo();
		[CCode(cname = "S_ISREG")]
		public bool is_regular();
		[CCode(cname = "S_ISLNK")]
		public bool is_link();
		[CCode(cname = "S_ISSOCK")]
		public bool is_sock();
		/**
		 * Converts the format mode to an ls-style long mode.
		 */
		public string to_string() {
			char attr[11];
			switch (this&FileMode.FMT) {
			case FileMode.FBLK :
				attr[0] = 'b';
				break;
			case FileMode.FCHR :
				attr[0] = 'c';
				break;
			case FileMode.FDIR :
				attr[0] = 'd';
				break;
			case FileMode.FIFO :
				attr[0] = 'p';
				break;
			case FileMode.FLNK :
				attr[0] = 'l';
				break;
			case FileMode.FREG :
				attr[0] = '-';
				break;
			case FileMode.FSOCK :
				attr[0] = 's';
				break;
			default :
				attr[0] = '?';
				break;
			}
			attr[1] = check_mode(FileMode.RUSR, 'r');
			attr[2] = check_mode(FileMode.WUSR, 'w');
			attr[3] = check_mode_x(FileMode.RUSR, FileMode.SUID, 's');
			attr[4] = check_mode(FileMode.RGRP, 'r');
			attr[5] = check_mode(FileMode.WGRP, 'w');
			attr[6] = check_mode_x(FileMode.RGRP, FileMode.SGID, 's');
			attr[7] = check_mode(FileMode.ROTH, 'r');
			attr[8] = check_mode(FileMode.WOTH, 'w');
			attr[9] = check_mode_x(FileMode.ROTH, FileMode.SVTX, 't');
			attr[10] = '\0';
			return ((string) attr).dup();
		}
		char check_mode(FileMode mode, char symbol) {
			return mode in this ? symbol : '-';
		}
		char check_mode_x(FileMode mode, FileMode modifier, char symbol) {
			if ((mode|modifier) in this) {
				return symbol.tolower();
			}
			if (modifier in this) {
				return symbol.toupper();
			}
			return mode in this ? 'x' : '-';
		}
	}
	/**
	 * Capabilities of system that affect index actions.
	 */
	[Flags]
	[CCode(cname = "unsigned int", cprefix = "GIT_INDEXCAP_", has_type_id = false)]
	public enum IndexCapability {
		IGNORE_CASE,
		NO_FILEMODE,
		NO_SYMLINKS,
		/**
		 * Read capabilites from the config of the owner object, looking at
		 * '''core.ignorecase''', '''core.filemode''', '''core.symlinks'''.
		 */
		FROM_OWNER
	}
	/**
	 * Extra behaviors to {@link Repository.init_ext}.
	 *
	 * In every case, the default behavior is the flag not set.
	 *
	 */
	[CCode(cname = "uint32_t", cprefix = "GIT_REPOSITORY_INIT_", has_type_id = false)]
	[Flags]
	public enum InitFlag {
		/**
		 * Create a bare repository with no working directory.
		 */
		BARE,
		/**
		 * Return an {@link Error.EXISTS} error if the path appears to already be
		 * an git repository.
		 */
		NO_REINIT,
		/**
		 * Normally a '''/.git/''' will be appended to the repo path for non-bare
		 * repos (if it is not already there), but passing this flag prevents that
		 * behavior.
		 */
		NO_DOTGIT_DIR,
		/**
		 * Make the path (and working directory) as needed.
		 *
		 * Init is always willing to create the '''.git''' directory even without
		 * this flag. This flag tells init to create the trailing component of the
		 * repo and workdir paths as needed.
		 */
		MKDIR,
		/**
		 * Recursively make all components of the repo and workdir paths as
		 * necessary.
		 */
		MKPATH,
		/**
		 * libgit2 normally uses internal templates to initialize a new repo. This
		 * flags enables external templates, looking the '''template_path''' from
		 * the options if set, or the '''init.templatedir''' global config if not,
		 * or falling back on '''/usr/share/git-core/templates''' if it exists.
		 */
		EXTERNAL_TEMPLATE
	}
	/**
	 * Basic type (loose or packed) of any git object
	 */
	[CCode(cname = "git_otype", cprefix = "GIT_OBJ_", has_type_id = false)]
	public enum ObjectType {
		/**
		 * Object can be any of the following
		 */
		ANY,
		/**
		 * Object is invalid
		 */
		BAD,
		/**
		 * Reserved for future use
		 */
		_EXT1,
		/**
		 * A commit object
		 */
		COMMIT,
		/**
		 * A tree (directory listing) object
		 */
		TREE,
		/**
		 * A file revision object
		 */
		BLOB,
		/**
		 * An annotated tag object
		 */
		TAG,
		/**
		 * Reserved for future use
		 */
		_EXT2,
		/**
		 * A delta, base is given by an offset
		 */
		OFS_DELTA,
		/**
		 * A delta, base is given by {@link object_id}
		 */
		REF_DELTA;
		/**
		 * Convert an object type to its string representation
		 */
		[CCode(cname = "git_object_type2string")]
		public unowned string to_string();

		/**
		 * Parse a string containing an object type
		 *
		 * @param str the string to convert
		 * @return the corresponding object type
		 */
		[CCode(cname = "git_object_string2type")]
		public static ObjectType from_string(string str);

		/**
		 * Determine if the given this type is a valid loose object type
		 *
		 * @return true if the type represents a valid loose object type, false otherwise.
		 */
		[CCode(cname = "git_object_typeisloose")]
		public bool is_loose();

		/**
		 * Get the size in bytes for the structure which holding this object type
		 */
		[CCode(cname = "git_object__size")]
		public size_t get_size();
	}

	[CCode(cname = "unsigned int", cprefix = "GIT_REPOSITORY_OPEN_", has_type_id = false)]
	[Flags]
	public enum OpenFlags {
		NO_SEARCH,
		CROSS_FS
	}
	[CCode(cname = "unsigned int", cprefix = "GIT_REF_FORMAT_", has_type_id = false)]
	[Flags]
	public enum ReferenceFormat {
		NORMAL,
		/**
		 * Control whether one-level refnames are accepted
		 *
		 * (i.e., refnames that do not contain multiple /-separated components)
		 */
		ALLOW_ONELEVEL,
		/**
		 * Interpret the provided name as a reference pattern for a refspec (as
		 * used with remote repositories).
		 *
		 * If this option is enabled, the name is allowed to contain a single *
		 * (<star>) in place of a one full pathname component (e.g., foo/<star>/bar
		 * but not foo/bar<star>).
		 */
		REFSPEC_PATTERN,
	}
	/**
	 * Basic type of any Git reference.
	 */
	[CCode(cname = "git_rtype", cprefix = "GIT_REF_", has_type_id = false)]
	[Flags]
	public enum ReferenceType {
		/**
		 * Invalid reference
		 */
		INVALID,
		/**
		 * A reference which points at an object id
		 */
		[CCode(cname = "GIT_REF_OID")]
		ID,
		/**
		 * A reference which points at another reference
		 */
		SYMBOLIC,
		LISTALL
	}
	/**
	 * Which operation remote operation has finished.
	 */
	[CCode(cname = "git_remote_completion_type", cprefix = "GIT_REMOTE_COMPLETION_", has_type_id = false)]
	public enum CompletionType {
		DOWNLOAD,
		INDEXING,
		ERROR
	}

	/**
	 * Kinds of reset operation.
	 */
	[CCode(cname = "git_reset_type", cprefix = "GIT_RESET_", has_type_id = false)]
	public enum ResetType {
		SOFT,
		MIXED,
		HARD
	}

	/**
	 * Actions that the smart transport can ask a subtransport to perform
	 */
	[CCode(cname = "git_smart_service_t", cprefix = "GIT_SERVICE_", has_type_id = false)]
	public enum SmartService {
		UPLOADPACK_LS,
		UPLOADPACK,
		RECEIVEPACK_LS,
		RECEIVEPACK
	}

	/**
	 * Sort order for revision walking.
	 */
	[CCode(cname = "int", cprefix = "GIT_SORT_", has_type_id = false)]
	[Flags]
	public enum Sorting {
		/**
		 * Sort the repository contents in no particular ordering;
		 * this sorting is arbitrary, implementation-specific
		 * and subject to change at any time.
		 * This is the default sorting for new walkers.
		 */
		NONE,
		/**
		 * Sort the repository contents in topological order
		 * (parents before children); this sorting mode
		 * can be combined with time sorting.
		 */
		TOPOLOGICAL,
		/**
		 * Sort the repository contents by commit time;
		 * this sorting mode can be combined with
		 * topological sorting.
		 */
		TIME,
		/**
		 * Iterate through the repository contents in reverse
		 * order; this sorting mode can be combined with
		 * any of the above.
		 */
		REVERSE
	}
	[CCode(cname = "unsigned int", cprefix = "GIT_STASH_", has_type_id = false)]
	[Flags]
	public enum StashFlag {
		DEFAULT,
		/**
		 * All changes already added to the index are left intact in the working
		 * directory
		 */
		KEEP_INDEX,
		/**
		 * All untracked files are also stashed and then cleaned up from the
		 * working directory
		 */
		INCLUDE_UNTRACKED,
		/**
		 * All ignored files are also stashed and then cleaned up from the working
		 * directory
		 */
		INCLUDE_IGNORED
	}

	[CCode(cname = "int", cprefix = "GIT_REPOSITORY_STATE_", has_type_id = false)]
	public enum State {
		NONE,
		MERGE,
		REVERT,
		CHERRY_PICK,
		BISECT,
		REBASE,
		REBASE_INTERACTIVE,
		REBASE_MERGE,
		APPLY_MAILBOX,
		APPLY_MAILBOX_OR_REBASE
	}

	/**
	 * Working directory file status
	 */
	[CCode(cname = "int", cprefix = "GIT_STATUS_", has_type_id = false)]
	public enum Status {
		CURRENT,
		INDEX_NEW,
		INDEX_MODIFIED,
		INDEX_DELETED,
		WT_NEW,
		WT_MODIFIED,
		WT_DELETED,
		IGNORED
	}
	/**
	 * Select the files on which to report status.
	 */
	[CCode(cname = "git_status_show_t", has_type_id = false, cprefix = "GIT_STATUS_SHOW_")]
	public enum StatusShow {
		/**
		 * The rough equivalent of '''git status --porcelain''' where each file
		 * will receive a callback indicating its status in the index and in the
		 * workdir.
		 */
		INDEX_AND_WORKDIR,
		/**
		 * Only make callbacks for index side of status.
		 *
		 * The status of the index contents relative to the HEAD will be given.
		 */
		INDEX_ONLY,
		/**
		 * Only make callbacks for the workdir side of status, reporting the status
		 * of workdir content relative to the index.
		 */
		WORKDIR_ONLY,
		/**
		 * Behave like index-only followed by workdir-only, causing two callbacks
		 * to be issued per file (first index then workdir).
		 *
		 * This is slightly more efficient than making separate calls. This makes
		 * it easier to emulate the output of a plain '''git status'''.
		 */
		INDEX_THEN_WORKDIR
	}

	/**
	 * Flags to control status callbacks
	 */
	[CCode(cname = "unsigned int", cprefix = "GIT_STATUS_OPT_", has_type_id = false)]
	public enum StatusControl {
		/**
		 * Callbacks should be made on untracked files.
		 *
		 * These will only be made if the workdir files are included in the status
		 * "show" option.
		 */
		INCLUDE_UNTRACKED,
		/**
		 * Ignored files should get callbacks.
		 *
		 * These callbacks will only be made if the workdir files are included in
		 * the status "show" option. Right now, there is no option to include all
		 * files in directories that are ignored completely.
		 */
		INCLUDE_IGNORED,
		/**
		 * Callbacks should be made even on unmodified files.
		 */
		INCLUDE_UNMODIFIED,
		/**
		 * Directories which appear to be submodules should just be skipped over.
		 */
		EXCLUDE_SUBMODULES,
		/**
		 * The contents of untracked directories should be included in the status.
		 *
		 * Normally if an entire directory is new, then just the top-level
		 * directory will be included (with a trailing slash on the entry name).
		 * Given this flag, the directory itself will not be included, but all the
		 * files in it will.
		 */
		RECURSE_UNTRACKED_DIRS,
		DEFAULTS
	}

	[CCode(cname = "git_submodule_update_t", cprefix = "GIT_SUBMODULE_UPDATE_", has_type_id = false)]
	public enum SubmoduleUpdate {
		DEFAULT,
		CHECKOUT,
		REBASE,
		MERGE,
		NONE
	}

	[CCode(cname = "git_submodule_ignore_t", cpreifx = "GIT_SUBMODULE_IGNORE_", has_type_id = false)]
	public enum SubmoduleIgnore {
		/**
		 * The working directory will be consider clean so long as there is a
		 * checked out version present.
		 */
		ALL,
		/**
		 * Only check if the HEAD of the submodule has moved for status.
		 *
		 * This is fast since it does not need to scan the working tree of the
		 * submodule at all.
		 */
		DIRTY,
		/**
		 * Examines the contents of the working tree but untracked files will not
		 * count as making the submodule dirty.
		 */
		UNTRACKED,
		/**
		 * Consider any change to the contents of the submodule from a clean
		 * checkout to be dirty, including the addition of untracked files.
		 *
		 * This is the default if unspecified.
		 */
		NONE
	}

	/**
	 * Submodule status
	 *
	 * Submodule info is contained in 4 places: the HEAD tree, the index, config
	 * files (both .git/config and .gitmodules), and the working directory. Any
	 * or all of those places might be missing information about the submodule
	 * depending on what state the repo is in. We consider all four places to
	 * build the combination of status flags.
	 *
	 * There are four values that are not really status, but give basic info
	 * about what sources of submodule data are available. These will be
	 * returned even if {@link Submodule.ignore} is set to {@link SubmoduleIgnore.ALL}.
	 *
	 * * {@link IN_HEAD} superproject head contains submodule
	 * * {@link IN_INDEX} superproject index contains submodule
	 * * {@link IN_CONFIG} superproject gitmodules has submodule
	 * * {@link IN_WD} superproject workdir has submodule
	 *
	 * The following values will be returned so long as ignore is not {@link SubmoduleIgnore.ALL}.
	 *
	 * * {@link INDEX_ADDED} in index, not in head
	 * * {@link INDEX_DELETED} in head, not in index
	 * * {@link INDEX_MODIFIED} index and head don't match
	 * * {@link WD_UNINITIALIZED} workdir contains empty directory
	 * * {@link WD_ADDED} in workdir, not index
	 * * {@link WD_DELETED} in index, not workdir
	 * * {@link WD_MODIFIED} index and workdir head don't match
	 *
	 * The following can only be returned if ignore is {@link SubmoduleIgnore.NONE} or {@link SubmoduleIgnore.UNTRACKED}.
	 *
	 * * {@link WD_INDEX_MODIFIED} submodule workdir index is dirty
	 * * {@link WD_WD_MODIFIED} submodule workdir has modified files
	 *
	 * Lastly, the following will only be returned for ignore {@link SubmoduleIgnore.NONE}.
	 *
	 * * {@link WD_UNTRACKED} wd contains untracked files
	 */
	[CCode(cname = "unsigned int", has_type_id = false, cprefix = "GIT_SUBMODULE_STATUS_")]
	public enum SubmoduleStatus {
		IN_HEAD,
		IN_INDEX,
		IN_CONFIG,
		IN_WD,
		INDEX_ADDED,
		INDEX_DELETED,
		INDEX_MODIFIED,
		WD_UNINITIALIZED,
		WD_ADDED,
		WD_DELETED,
		WD_MODIFIED,
		WD_INDEX_MODIFIED,
		WD_WD_MODIFIED,
		WD_UNTRACKED;
		[CCode(cname = "GIT_SUBMODULE_STATUS_IS_UNMODIFIED")]
		public bool is_unmodified();
		[CCode(cname = "GIT_SUBMODULE_STATUS_IS_WD_DIRTY")]
		public bool is_wd_dirty();
	}
	/**
	 * Available tracing levels.
	 *
	 * When tracing is set to a particular level, callers will be provided
	 * tracing at the given level and all lower levels.
	 */
	[CCode(cname = "git_trace_level_t", cprefix = "GIT_TRACE_", has_type_id = false)]
	public enum Trace {
		/**
		 * No tracing will be performed.
		 */
		NONE,
		/**
		 * Severe errors that may impact the program's execution
		 */
		FATAL,
		/**
		 * Errors that do not impact the program's execution
		 */
		ERROR,
		/**
		 * Warnings that suggest abnormal data
		 */
		WARN,
		/**
		 * Informational messages about program execution
		 */
		INFO,
		/**
		 * Detailed data that allows for debugging
		 */
		DEBUG,
		/**
		 * Exceptionally detailed debugging data
		 */
		TRACE;
		/**
		 * Sets the system tracing configuration to the specified level with the
		 * specified callback.
		 *
		 * When system events occur at a level equal to, or lower than, the given
		 * level they will be reported to the given callback.
		 */
		[CCode(cname = "git_trace_set")]
		public Error setup(Tracer tracer);
	}
	[CCode(cname = "int", cprefix = "GIT_TRANSPORTFLAGS_", has_type_id = false)]
	public enum TransportFlags {
		NONE,
		/**
		 * If the connection is secured with SSL/TLS, the authenticity of the
		 * server certificate should not be verified.
		 */
		NO_CHECK_CERT
	}

	/**
	 * Tree traversal modes
	 */
	[CCode(cname = "git_treewalk_mode", cprefix = "GIT_TREEWALK_", has_type_id = false)]
	public enum WalkMode {
		PRE,
		POST
	}

	[CCode(cname = "git_attr_foreach_cb", has_type_id = false)]
	public delegate Error AttributeForEach(string name, string? val);
	[CCode(cname = "git_branch_foreach_cb")]
	public delegate int Branch(string branch_name, BranchType branch_type);
	/**
	 * Callback for notification of a file during checkout.
	 *
	 *
	 * Notification callbacks are made prior to modifying any files on disk.
	 *
	 * @return true to cancel the checkout; false otherwise.
	 */
	[CCode(cname = "git_checkout_notify_cb", has_type_id = false)]
	public delegate bool CheckoutNotifier(CheckoutNotify why, string path, diff_file baseline, diff_file target, diff_file workdir);
	/**
	 *
	 * The implementation of the callback has to respect the
	 * following rules:
	 *
	 * @param content will have to be filled. The maximum number of bytes that
	 * the buffer can accept per call is the length of the array.
	 *
	 * @return The callback is expected to return the number of bytes
	 * written to content. When there is no more data to stream, the callback
	 * should return 0. This will prevent it from being invoked anymore. When an
	 * error occurs, the callback should return -1.
	 */
	[CCode(cname = "git_blob_chunk_cb")]
	public delegate int ChunkSource([CCode(array_length_type = "size_t")] uint8[] content);

	[CCode(cname = "git_config_foreach_cb")]
	public delegate int ConfigForEach(config_entry entry);
	/**
	 * made on files where the index differs from the working
	 * directory but the rules do not allow update.
	 *
	 * All such callbacks will be made before any changes are made to the
	 * working directory.
	 * @return true to abort the checkout.
	 */
	public delegate bool Conflict(string conflicting_path, object_id index_id, uint index_mode, uint wd_mode);
	/**
	 * A function which creates a new subtransport for the smart transport
	 */
	[CCode(cname = "git_smart_subtransport_cb", has_target = false)]
	public delegate Error CreateSubTransport(out smart_subtransport? subtransport, transport owner);
	/**
	 * Signature of a function which creates a transport
	 */
	[CCode(cname = "git_transport_cb")]
	public delegate Error CreateTransport(out transport? transport, Remote owner);

	/**
	 * Signature of a function which acquires a credential object.
	 *
	 * @param cred The newly created credential object.
	 * @param url The resource for which we are demanding a credential.
	 * @param allowed_types A bitmask stating which cred types are OK to return.
	 */
	[CCode(cname = "git_cred_acquire_cb", has_type_id = false)]
	public delegate Error CredAcquire(out cred? cred, string url, CredTypes allowed_types);
	[CCode(has_target = false, has_type_id = false)]
	public delegate void CredFree(owned cred cred);

	/**
	 * When printing a diff, callback that will be made to output each line of
	 * text.
	 * @return true to stop iteration
	 */
	[CCode(cname = "git_diff_data_cb", simple_generics = true, has_target = false, has_type_id = false)]
	public delegate bool DiffData<T>(diff_delta delta, diff_range range, DiffLineType line_origin, [CCode(array_length_type = "size_t")] char[] formatted_output, T context);
	/**
	 * When iterating over a diff, callback that will be made per file.
	 */
	[CCode(cname = "git_diff_file_cb", simple_generics = true, has_target = false, has_type_id = false)]
	public delegate Error DiffFile<T>(diff_delta delta, float progress, T context);

	/**
	 * When iterating over a diff, callback that will be made per hunk.
	 */
	[CCode(cname = "git_diff_hunk_cb", simple_generics = true, has_target = false, has_type_id = false)]
	public delegate Error DiffHunk<T>(diff_delta delta, diff_range range, [CCode(array_length_type = "size_t")] char[] header, T context);

	/**
	 * When iterating over a diff, callback that will be made per text diff
	 * line.
	 * @return true to stop iteration
	 */
	[CCode(cname = "git_diff_line_fn", simple_generics = true, has_target = false, has_type_id = false)]
	public delegate bool DiffLine<T>(T context, diff_delta delta, DiffLineType line_origin, [CCode(array_length_type = "size_t")] uint8[] content);
	/*
	 * Diff notification callback function.
	 *
	 * The callback will be called for each file, just before the {@link
	 * DeltaType} gets inserted into the diff list.
	 *
	 * When the callback:
	 * - returns < 0, the diff process will be aborted.
	 * - returns > 0, the delta will not be inserted into the diff list, but the
	 *             diff process continues.
	 * - returns 0, the delta is inserted into the diff list, and the diff process
	 *             continues.
	 */
	[CCode(cname = "git_diff_notify_cb", has_type_id = false)]
	public delegate int DiffNotify(DiffList diff_so_far, diff_delta delta_to_add, string matched_pathspec);

	/**
	 * When printing a diff, callback that will be made to output each line of
	 * text.
	 * @return true to stop iteration
	 */
	[CCode(cname = "git_diff_data_cb", has_type_id = false)]
	public delegate bool DiffOutput(diff_delta delta, diff_range range, DiffLineType line_origin, [CCode(array_length_type = "size_t")] char[] formatted_output);
	[CCode(cname = "git_repository_fetchhead_foreach_cb")]
	public delegate bool FetchHeadForEach(string ref_name, string remote_url, object_id id, bool is_merge);

	[CCode(cname = "git_treebuilder_filter_cb", has_type_id = false)]
	public delegate bool Filter(TreeEntry entry);
	[CCode(cname = "git_headlist_cb", has_type_id = false)]
	public delegate int Head(remote_head head);
	[CCode(cname = "git_repository_mergehead_foreach_cb", has_type_id = false)]
	public delegate bool MergeHeadForEach(object_id id);
	/**
	 * Called to process a note.
	 * @param blob_id id of the blob containing the message
	 * @param annotated_object_id id of the git object being annotated
	 */
	[CCode(cname = "git_note_foreach_cb", has_type_id = false)]
	public delegate Error NoteForEach(object_id blob_id, object_id annotated_object_id);
	[CCode(cname = "git_odb_foreach_cb", has_type_id = false)]
	public delegate Error ObjectIdForEach(object_id id);
	[CCode(cname = "git_packbuilder_foreach_cb", has_type_id = false)]
	public delegate int PackBuilderForEach([CCode(array_length_type = "size_t")] uint8[] buffer);
	public delegate bool PushForEach(string ref_spec, string msg);
	[CCode(cname = "git_checkout_progress_cb")]
	public delegate void Progress(string path, size_t completed_steps, size_t total_steps);

	/**
	 * Suggests that the given refdb compress or optimize its references.
	 *
	 * This mechanism is implementation specific. (For on-disk reference
	 * databases, this may pack all loose references.)
	 */
	[CCode(has_target = false, has_type_id = false)]
	public delegate Error RefDbCompress(refdb_backend backend);
	/**
	 * Deletes the given reference from the refdb.
	 */
	[CCode(has_target = false, has_type_id = false)]
	public delegate Error RefDbDelete(refdb_backend backend, Reference reference);
	/**
	 * Queries the refdb backend to determine if the given ref_name
	 * exists.
	 */
	[CCode(has_target = false, has_type_id = false)]
	public delegate Error RefDbExists(out bool exists, refdb_backend backend, string ref_name);
	/**
	 * Enumerates each reference in the refdb.
	 */
	[CCode(has_target = false, has_type_id = false)]
	public delegate Error RefDbForEach(refdb_backend backend, ReferenceType list_flags, ReferenceForEach @foreach);
	/**
	 * Enumerates each reference in the refdb that matches the given glob string.
	 */
	[CCode(has_target = false, has_type_id = false)]
	public delegate Error RefDbForEachGlob(refdb_backend backend, string glob, ReferenceType list_flags, ReferenceForEach @foreach);
	/**
	 * Frees any resources held by the refdb.
	 */
	[CCode(has_target = false, has_type_id = false)]
	public delegate void RefDbFree(owned refdb_backend backend);
	/**
	 * Queries the refdb backend for a given reference.
	 */
	[CCode(has_target = false, has_type_id = false)]
	public delegate Error RefDbLookup(out Reference? reference, refdb_backend backend, string ref_name);
	/**
	 * Writes the given reference to the refdb.
	 */
	[CCode(has_target = false, has_type_id = false)]
	public delegate Error RefDbWrite(refdb_backend backend, Reference reference);

	[CCode(cname = "git_reference_foreach_cb", has_type_id = false)]
	public delegate bool ReferenceForEach(string refname);
	[CCode(simple_generics = true, has_type_id = false)]
	public delegate void RemoteProgress<T>(uint8[] str, T data);
	[CCode(has_target = false, simple_generics = true, has_type_id = false)]
	public delegate Error RemoteCompletion<T>(CompletionType type, T data);
	[CCode(has_target = false, simple_generics = true, has_type_id = false)]
	public delegate Error RemoteUpdateTips<T>(string refname, object_id a, object_id b, T data);
	/**
	 * When iterating over all the stashed states, callback that will be issued
	 * per entry.
	 *
	 * @param index The position within the stash list. 0 points to the most
	 * recent stashed state.
	 * @param message The stash message.
	 * @param stash_id The commit id of the stashed state.
	 * @return 0 on success, GIT_EUSER on non-zero callback, or error code
	 */
	[CCode(cname = "git_stash_cb")]
	public delegate Error StashForEach(size_t index, string message, object_id stash_id);
	/**
	 * Function to receive status on individual files
	 *
	 * @param file the relative path to the file from the root of the repository.
	 */
	[CCode(cname = "git_status_cb", has_type_id = false)]
	public delegate Error StatusForEach(string file, Status status);
	public delegate Error SubmoduleForEach(string name);
	[CCode(cname = "git_tag_foreach_cb", has_type_id = false)]
	public delegate bool TagForEach(string name, object_id id);
	/**
	 * An instance for a tracing function
	 */
	[CCode(cname = "git_trace_callback", has_type_id = false, has_target = false)]
	public delegate void Tracer(Trace level, string msg);
	/**
	 * Type for progress callbacks during indexing.
	 *
	 * @param stats Structure containing information about the state of the transfer
	 * @return an error to cancel the transfer.
	 */
	[CCode(cname = "git_transfer_progress_callback", has_type_id = false)]
	public delegate Error TransferProgress(transfer_progress stats);

	[CCode(has_target = false, has_type_id = false)]
	public delegate void TransportCancel(transport transport);
	[CCode(has_target = false, has_type_id = false)]
	public delegate Error TransportClose(transport transport);
	[CCode(has_target = false, has_type_id = false)]
	public delegate Error TransportConnect(transport transport, string url, CredAcquire cred_acquire, Direction direction, TransportFlags flags);
	[CCode(has_target = false, has_type_id = false)]
	public delegate Error TransportDownloadPack(transport transport, Repository repo, out transfer_progress stats, Progress progress);
	[CCode(has_target = false, has_type_id = false)]
	public delegate void TransportFree(owned transport? transport);
	[CCode(has_target = false, has_type_id = false)]
	public delegate bool TransportIsConnected(transport transport);
	[CCode(has_target = false, has_type_id = false)]
	public delegate Error TransportList(transport transport, Head list);
	[CCode(cname = "git_transport_message_cb", has_type_id = false, has_target = false, simple_generics = true)]
	public delegate void TransportMessage<T>(uint8[] message, T data);
	[CCode(has_target = false, has_type_id = false)]
	public delegate Error TransportNegotiatFetch(transport transport, Repository repo, [CCode(array_length_type = "size_t")] remote_head[] refs);
	[CCode(has_target = false, has_type_id = false)]
	public delegate Error TransportPush(transport transport, Push push);
	[CCode(has_target = false, has_type_id = false)]
	public delegate Error TransportReadFlags(transport transport, out TransportFlags flags);
	[CCode(has_target = false, has_type_id = false)]
	public delegate Error TransportSetCallbacks<T>(transport transport, TransportMessage<T> progress, TransportMessage<T> error, T data);

	[CCode(has_target = false, has_type_id = false)]
	public delegate Error SubTransportAction(out smart_subtransport_stream? stream, smart_subtransport transport, string url, SmartService action);
	[CCode(has_target = false, has_type_id = false)]
	public delegate Error SubTransportClose(smart_subtransport transport);
	[CCode(has_target = false, has_type_id = false)]
	public delegate void SubTransportFree(owned smart_subtransport? transport);
	[CCode(has_target = false, has_type_id = false)]
	public delegate void SubTransportStreamFree(owned smart_subtransport_stream? stream);
	[CCode(has_target = false, has_type_id = false)]
	public delegate Error SubTransportStreamRead(smart_subtransport_stream stream, [CCode(array_length_type = "size_t")] uint8[] buffer, out size_t bytes_read);
	[CCode(has_target = false, has_type_id = false)]
	public delegate Error SubTransportStreamWrite(smart_subtransport_stream stream, [CCode(array_length_type = "size_t")] uint8[] buffer);

	[CCode(cname = "git_treewalk_cb", has_type_id = false)]
	public delegate int TreeWalker(string root, TreeEntry entry);
	[CCode(has_target = false)]
	public delegate Error Update(string refname, object_id old, object_id @new);

	/**
	 * Clean up message from excess whitespace and make sure that the last line
	 * ends with a new line.
	 *
	 * @param message_out The buffer which will be filled with the cleaned up
	 * message.
	 * @param message The message to be prettified.
	 *
	 * @param strip_comments remove lines starting with a "#".
	 */
	[CCode(cname = "git_message_prettify")]
	public Error prettify_message([CCode(array_length_type = "size_t")] uint8[] message_out, string message, bool strip_comments);

	namespace Option {
		[CCode(cname = "int", cprefix = "GIT_OPT_")]
		private enum _Option {
			GET_MWINDOW_SIZE,
			SET_MWINDOW_SIZE,
			GET_MWINDOW_MAPPED_LIMIT,
			SET_MWINDOW_MAPPED_LIMIT,
			GET_SEARCH_PATH,
			SET_SEARCH_PATH,
			GET_ODB_CACHE_SIZE,
			SET_ODB_CACHE_SIZE;
			[CCode(cname = "git_libgit2_opts")]
			public Error opts(...);
		}
		public size_t get_mwindow_mapped_limit() {
			size_t s = 0;
			_Option.GET_MWINDOW_MAPPED_LIMIT.opts(out s);
			return s;
		}
		/**
		 * Set the maximum amount of memory that can be mapped at any time by the
		 * library.
		 */
		public void set_mwindow_mapped_limit(size_t size) {
			_Option.SET_MWINDOW_MAPPED_LIMIT.opts(size);
		}
		/**
		 * Set the maximum mmap window size.
		 */
		public size_t get_mwindow_size() {
			size_t s = 0;
			_Option.GET_MWINDOW_SIZE.opts(out s);
			return s;
		}
		public void set_mwindow_size(size_t size) {
			_Option.SET_MWINDOW_SIZE.opts(size);
		}
		/**
		 * Get the size of the libgit2 odb cache.
		 */
		public size_t get_odb_cache_size() {
			size_t s = 0;
			_Option.GET_ODB_CACHE_SIZE.opts(out s);
			return s;
		}
		/**
		 * Set the size of the of the libgit2 odb cache.
		 *
		 * This needs to be done before {@link Repository.open} is called, since
		 * it initializes the odb layer. Defaults to 128.
		 */
		public void set_odb_cache_size(size_t size = 128) {
			_Option.SET_ODB_CACHE_SIZE.opts(size);
		}
		/**
		 * Set the search path for a given level of config data.
		 *
		 * @param level must be one of {@link ConfigLevel.SYSTEM},
		 * {@link ConfigLevel_GLOBAL}, or {@link ConfigLevel.XDG}.
		 */
		public string get_search_path(ConfigLevel level) {
			uint8[] buffer = new uint8[64];
			while (_Option.GET_SEARCH_PATH.opts(level, (void*)buffer, (size_t) buffer.length) == Error.BUFS) {
				buffer = new uint8[buffer.length * 2];
			}
			return ((string)buffer).dup();
		}
		public void set_search_path(ConfigLevel level, string path) {
			_Option.SET_SEARCH_PATH.opts(level, path);
		}
	}

	/**
	 * Set the error message to a special value for memory allocation failure.
	 *
	 * The normal {@link ErrClass.raise} function attempts to duplicate the
	 * string that is passed in. This is not a good idea when the error in
	 * question is a memory allocation failure. That circumstance has a special
	 * setter function that sets the error string to a known and statically
	 * allocated internal value.
	 */
	[CCode(cname = "giterr_set_oom")]
	public void raise_oom();


	[CCode(cname = "char*", has_type_id = false)]
	[SimpleType]
	private struct unstr {
		[CCode(cname = "strdup")]
		public string dup();
	}
}


