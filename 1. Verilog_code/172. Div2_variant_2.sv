//SystemVerilog
module Div2 #(parameter W=4)(
    input [W-1:0] a, b,
    output reg [W-1:0] q,
    output reg [W:0] r
);

    // Internal signals
    reg [W:0] r_next;
    reg [W-1:0] q_next;
    reg [W:0] r_temp;
    reg [W-1:0] q_temp;
    reg [W:0] r_shift;
    reg [W:0] r_sub;
    reg [W-1:0] q_update;
    reg [W:0] r_update;

    // Initialize registers
    always @(*) begin
        r_temp = a;
        q_temp = 0;
    end

    // Shift operation
    always @(*) begin
        r_shift = r_temp << 1;
    end

    // Comparison and subtraction
    always @(*) begin
        q_update = q_temp;
        r_update = r_shift;
        if(r_shift >= b) begin
            q_update[W-1] = 1'b1;
            r_update = r_shift - b;
        end else begin
            q_update[W-1] = 1'b0;
        end
    end

    // Update result registers
    always @(*) begin
        r_next = r_update;
        q_next = q_update;
    end

    // Output assignment
    always @(*) begin
        r = r_next;
        q = q_next;
    end

endmodule