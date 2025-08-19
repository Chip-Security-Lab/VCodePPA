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

    localparam IDLE=3'b000, SYNC1=3'b001, SYNC2=3'b010, SYNC3=3'b011, VALID=3'b100;
    reg [2:0] state, next;
    reg toggle_src;
    reg [2:0] toggle_dst_sync;
    reg [WIDTH-1:0] data_reg;
    reg [WIDTH-1:0] data_stage1, data_stage2;
    
    // Source domain
    always @(posedge src_clk or posedge rst) begin
        if (rst) begin
            toggle_src <= 1'b0;
            data_reg <= {WIDTH{1'b0}};
        end else if (src_valid) begin
            toggle_src <= ~toggle_src;
            data_reg <= data_in;
        end
    end
    
    // Destination domain - Stage 1
    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            toggle_dst_sync <= 3'b000;
            data_stage1 <= {WIDTH{1'b0}};
        end else begin
            toggle_dst_sync <= {toggle_dst_sync[1:0], toggle_src};
            data_stage1 <= data_reg;
        end
    end
    
    // Destination domain - Stage 2
    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            data_stage2 <= {WIDTH{1'b0}};
        end else begin
            state <= next;
            data_stage2 <= data_stage1;
        end
    end
    
    // Destination domain - Stage 3
    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            data_out <= {WIDTH{1'b0}};
            dst_valid <= 1'b0;
        end else begin
            dst_valid <= (state == VALID);
            data_out <= (state == VALID) ? data_stage2 : data_out;
        end
    end
    
    // Next state logic
    always @(*) begin
        case (state)
            IDLE: next = (toggle_dst_sync[2] != toggle_dst_sync[1]) ? SYNC1 : IDLE;
            SYNC1: next = SYNC2;
            SYNC2: next = SYNC3;
            SYNC3: next = VALID;
            VALID: next = IDLE;
            default: next = IDLE;
        endcase
    end

endmodule