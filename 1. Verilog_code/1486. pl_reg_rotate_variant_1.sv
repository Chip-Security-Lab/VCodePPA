//SystemVerilog
module pl_reg_rotate #(
    parameter W = 8
)(
    input wire              clk,    // System clock
    input wire              load,   // Load control signal
    input wire              rotate, // Rotate control signal
    input wire [W-1:0]      d_in,   // Data input
    output reg [W-1:0]      q       // Data output
);

    // Pipeline stage signals
    reg load_stage1, rotate_stage1;
    reg [W-1:0] d_in_stage1;
    reg [W-1:0] q_next;
    
    // Control signals pipelining
    always @(posedge clk) begin
        load_stage1 <= load;
        rotate_stage1 <= rotate;
        d_in_stage1 <= d_in;
    end
    
    // Data path logic - separated from control
    always @(*) begin
        if (load_stage1)
            q_next = d_in_stage1;
        else if (rotate_stage1)
            q_next = {q[W-2:0], q[W-1]};
        else
            q_next = q;
    end
    
    // Output register stage
    always @(posedge clk) begin
        q <= q_next;
    end

endmodule