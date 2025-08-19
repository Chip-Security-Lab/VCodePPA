//SystemVerilog
// SystemVerilog
// IEEE 1364-2005 compliant
module ArithShift #(parameter N=8) (
    input wire clk,
    input wire rstn,
    input wire arith_shift,
    input wire s_in,
    output reg [N-1:0] q,
    output reg carry_out
);

    // Pipeline registers to cut critical path
    reg arith_shift_r;
    reg [N-1:0] q_r;
    reg s_in_r;
    
    // Intermediate computation results
    reg next_carry;
    reg [N-1:0] next_q;
    
    // Combined sequential logic block with all posedge clk or negedge rstn triggered logic
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            // Reset all sequential elements
            arith_shift_r <= 1'b0;
            q_r <= {N{1'b0}};
            s_in_r <= 1'b0;
            q <= {N{1'b0}};
            carry_out <= 1'b0;
        end else begin
            // Input pipeline stage
            arith_shift_r <= arith_shift;
            q_r <= q;
            s_in_r <= s_in;
            
            // Output stage (using computed next_q and next_carry)
            q <= next_q;
            carry_out <= next_carry;
        end
    end
    
    // Combinational logic using pipelined inputs
    always @(*) begin
        if (arith_shift_r) begin
            // Arithmetic right shift: sign extension
            next_carry = q_r[0];
            next_q = {q_r[N-1], q_r[N-1:1]};
        end else begin
            // Logical left shift
            next_carry = q_r[N-1];
            next_q = {q_r[N-2:0], s_in_r};
        end
    end

endmodule