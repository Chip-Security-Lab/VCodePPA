//SystemVerilog
module full_adder_sync #(
    parameter WIDTH = 4,
    parameter DEPTH = 2
)(
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    input wire cin,
    output reg [WIDTH-1:0] sum,
    output reg cout
);
    reg [1:0] state;
    reg [WIDTH-1:0] p, g;
    reg [WIDTH:0] carry;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 2'b00;
            carry <= 0;
            p <= 0;
            g <= 0;
        end else begin
            case (state)
                2'b00: begin
                    if (en) begin
                        // Generate propagate and generate signals
                        p <= a ^ b;
                        g <= a & b;
                        carry[0] <= cin;
                        state <= 2'b01;
                    end
                end
                2'b01: begin
                    // Manchester carry chain
                    for (int i = 0; i < WIDTH; i = i + 1) begin
                        carry[i+1] <= g[i] | (p[i] & carry[i]);
                    end
                    state <= 2'b10;
                end
                2'b10: begin
                    // Calculate final sum
                    sum <= p ^ carry[WIDTH-1:0];
                    cout <= carry[WIDTH];
                    state <= 2'b00;
                end
                default: state <= 2'b00;
            endcase
        end
    end
endmodule