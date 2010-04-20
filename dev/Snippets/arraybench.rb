module Kernel
  # tiny bench method
  def bench(n=100, runs=10, &b)
    n = n.to_i
    t = []
    runs.times do
      a = Time.now
      n.times(&b)
      t << (Time.now-a)*1000/n
    end
    mean   = t.inject { |a,b| a+b }.quo(t.size)
    stddev = t.map { |a| (a-mean)**2 }.inject { |a,b| a+b }.quo(t.size)**0.5
    [mean, stddev]
  end

  # tiny bench method with nice printing
  def pbench(n=1, runs=5, &b)
    m, s = *bench(n,runs,&b)
    p    = (100.0*s)/m
    printf "ø %fms (%.1f%%)\n", m, p
  end
end

States = :a, :b, :c, :d, :e, :f, :g

pbench 1e3, 5 do
  r = []
  1000.times do r << States.at(rand(7)) end
  r.uniq.
end
  