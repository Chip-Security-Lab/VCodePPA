//SystemVerilog
module counter_sync_inc #(parameter WIDTH=8) (
    input clk, rst_n, en,
    output reg [WIDTH-1:0] cnt
);
    wire [WIDTH-1:0] next_cnt;
    wire [WIDTH:0] carry;
    
    // Manchester carry-chain adder implementation
    assign carry[0] = en;  // Carry-in is the enable signal
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_adder
            assign next_cnt[i] = cnt[i] ^ carry[i];
            assign carry[i+1] = cnt[i] & carry[i];
        end
    endgenerate
    
    always @(posedge clk) begin
        if (!rst_n) 
            cnt <= {WIDTH{1'b0}};
        else
            cnt <= next_cnt;
    end
endmodule