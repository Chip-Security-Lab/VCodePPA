//SystemVerilog
module wave19_beep #(
    parameter BEEP_ON  = 50,
    parameter BEEP_OFF = 50,
    parameter WIDTH    = 8
)(
    input  wire clk,
    input  wire rst,
    output reg  beep_out
);
    reg [WIDTH-1:0] cnt;
    reg             state;

    // Conditional Invert Subtractor function
    function [WIDTH-1:0] cond_invert_sub;
        input [WIDTH-1:0] a;
        input [WIDTH-1:0] b;
        reg   [WIDTH-1:0] b_inv;
        reg   carry_in;
        begin
            carry_in = 1'b1;
            b_inv = ~b;
            cond_invert_sub = a + b_inv + carry_in;
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt      <= 0;
            state    <= 0;
            beep_out <= 0;
        end else begin
            if ((state == 0) && (cond_invert_sub(cnt, (BEEP_ON - 1)) < {WIDTH{1'b1}})) begin
                cnt <= cnt + 1;
            end else if ((state == 0) && !(cond_invert_sub(cnt, (BEEP_ON - 1)) < {WIDTH{1'b1}})) begin
                cnt      <= 0;
                state    <= 1;
                beep_out <= 0;
            end else if ((state == 1) && (cond_invert_sub(cnt, (BEEP_OFF - 1)) < {WIDTH{1'b1}})) begin
                cnt <= cnt + 1;
            end else if ((state == 1) && !(cond_invert_sub(cnt, (BEEP_OFF - 1)) < {WIDTH{1'b1}})) begin
                cnt      <= 0;
                state    <= 0;
                beep_out <= 1;
            end
        end
    end
endmodule