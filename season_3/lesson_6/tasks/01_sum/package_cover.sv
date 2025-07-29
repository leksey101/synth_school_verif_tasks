package package_cover;

    class class_cover;

        covergroup sum_cg 
            with function sample (logic [7:0] cur_a, logic [7:0] cur_b);
            a_cp: coverpoint cur_a {
                bins a1 [] = {[0:255]};
            }
    
            b_cp: coverpoint cur_b {
                bins b1 [] = {[0:255]};
            }
        endgroup

        function new ();
            sum_cg = new();
        endfunction
        
    endclass
endpackage