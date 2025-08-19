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
            if (state == VALID) begin
                data_out <= data_reg;
                dst_valid <= 1'b1;
            end else dst_valid <= 1'b0;
        end
    
    always @(*)
        case (state)
            IDLE: next = (toggle_dst_sync[1] != toggle_dst_sync[0]) ? SYNC1 : IDLE;
            SYNC1: next = SYNC2;
            SYNC2: next = VALID;
            VALID: next = IDLE;
        endcase
endmodule