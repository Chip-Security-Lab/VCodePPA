//SystemVerilog
module CrossCoupleLatch (
    input set, reset,
    output q, qn
);

    // Internal signals
    reg q_reg, qn_reg;
    
    // Optimized latch logic using direct assignment
    always @* begin
        if (set && !reset)
            {q_reg, qn_reg} = 2'b10;
        else if (reset && !set)
            {q_reg, qn_reg} = 2'b01;
        else
            {q_reg, qn_reg} = {q_reg, qn_reg}; // Hold state
    end
    
    // Direct output assignment without extra modules
    assign q = q_reg;
    assign qn = qn_reg;

endmodule