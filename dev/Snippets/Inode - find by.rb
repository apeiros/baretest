Dir.glob('../../**/*/') { |path|
  break path if File.stat(path).ino == find_this_inode_number
}

suggestion is to start searching from the best match using the original path
also use stat(path).dev to stay on the same device