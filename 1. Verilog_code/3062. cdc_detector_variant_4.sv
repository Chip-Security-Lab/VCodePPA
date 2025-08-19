//SystemVerilog
module cdc_detector #(
    parameter WIDTH = 8
)(
    input wire src_clk, dst_clk, rst,
    input wire [WIDTH-1:0] data_in,
    input wire src_valid,
    output reg [WIDTH-1:0] data_out,
    output reg dst_valid
);
    localparam IDLE=2'b00, SYNC1=2'b01, SYNC2=2'b10, VALID=2'b11;
    reg [1:0] state, next;
    reg toggle_src;
    reg [1:0] toggle_dst_sync;
    reg [WIDTH-1:0] data_reg;
    
    // LUT-based state transition logic
    reg [3:0] state_lut [0:15];
    initial begin
        state_lut[0] = 4'b0000; // IDLE -> IDLE
        state_lut[1] = 4'b0001; // IDLE -> SYNC1
        state_lut[2] = 4'b0010; // SYNC1 -> SYNC2
        state_lut[3] = 4'b0011; // SYNC2 -> VALID
        state_lut[4] = 4'b0000; // VALID -> IDLE
    end
    
    always @(posedge src_clk or posedge rst)
        if (rst) begin
            toggle_src <= 1'b0;
            data_reg <= {WIDTH{1'b0}};
        end else if (src_valid) begin
            toggle_src <= ~toggle_src;
            data_reg <= data_in;
        end
    
    always @(posedge dst_clk or posedge rst)
        if (rst) begin
            state <= IDLE;
            toggle_dst_sync <= 2'b00;
            data_out <= {WIDTH{1'b0}};
            dst_valid <= 1'b0;
        end else begin
            toggle_dst_sync <= {toggle_dst_sync[0], toggle_src};
            state <= next;
            data_out <= (state == VALID) ? data_reg : data_out;
            dst_valid <= (state == VALID);
        end
    
    always @(*)
        if (state == IDLE && toggle_dst_sync[1] == toggle_dst_sync[0])
            next = state_lut[0][1:0];
        else if (state == IDLE && toggle_dst_sync[1] != toggle_dst_sync[0])
            next = state_lut[1][1:0];
        else if (state == SYNC1 && toggle_dst_sync[1] == toggle_dst_sync[0])
            next = state_lut[2][1:0];
        else if (state == SYNC1 && toggle_dst_sync[1] != toggle_dst_sync[0])
            next = state_lut[3][1:0];
        else if (state == VALID)
            next = state_lut[4][1:0];
        else
            next = IDLE;
endmodule