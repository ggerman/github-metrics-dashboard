# ================================================================
# Incluir helpers en todos los tests
# ================================================================

class Minitest::Test
  include TestHelper

  # Setup que corre antes de cada test
  def setup
    @temp_dir = Dir.mktmpdir
  end

  # Teardown que corre después de cada test
  def teardown
    if @temp_dir && Dir.exist?(@temp_dir)
      FileUtils.remove_entry @temp_dir
    end
  end
end