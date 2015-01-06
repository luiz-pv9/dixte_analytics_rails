# The App model includes the Mongoid::Document API instead of raw interaction
# with the database because there is not performance concern. Also, Mongoid
# helps with common operations (creating, editing, deleting).
class App
	include Mongoid::Document
end