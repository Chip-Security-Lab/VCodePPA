//SystemVerilog
module MuxGatedClock #(parameter W=4) (
    input wire gclk,
    input wire en,
    input wire [3:0][W-1:0] din,
    input wire [1:0] sel,
    output reg [W-1:0] q
);

    // Clock gating logic
    wire clk_en;
    assign clk_en = gclk & en;

    // Data path pipeline with lookahead carry subtractor
    reg [W-1:0] data_reg;
    wire [W-1:0] sel_data;
    wire [W-1:0] carry_lookahead;
    wire [W-1:0] borrow_out;
    
    // Mux selection
    assign sel_data = din[sel];
    
    // Lookahead carry subtractor implementation
    assign carry_lookahead[0] = 1'b1;
    assign carry_lookahead[1] = ~sel_data[0];
    assign carry_lookahead[2] = ~(sel_data[1] & carry_lookahead[1]);
    assign carry_lookahead[3] = ~(sel_data[2] & carry_lookahead[2]);
    
    assign borrow_out[0] = ~sel_data[0];
    assign borrow_out[1] = ~(sel_data[1] ^ carry_lookahead[1]);
    assign borrow_out[2] = ~(sel_data[2] ^ carry_lookahead[2]);
    assign borrow_out[3] = ~(sel_data[3] ^ carry_lookahead[3]);

    always @(posedge clk_en) begin
        data_reg <= borrow_out;
        q <= data_reg;
    end

endmodule