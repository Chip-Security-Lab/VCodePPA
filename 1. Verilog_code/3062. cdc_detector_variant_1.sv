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

    // State encoding
    localparam IDLE = 2'b00, SYNC1 = 2'b01, SYNC2 = 2'b10, VALID = 2'b11;
    
    // Source domain registers
    reg toggle_src;
    reg [WIDTH-1:0] data_reg;
    
    // Destination domain registers - Stage 1
    reg [1:0] toggle_dst_sync_stage1;
    reg [WIDTH-1:0] data_reg_stage1;
    reg src_valid_stage1;
    
    // Destination domain registers - Stage 2
    reg [1:0] toggle_dst_sync_stage2;
    reg [WIDTH-1:0] data_reg_stage2;
    reg src_valid_stage2;
    
    // Destination domain registers - Stage 3
    reg [1:0] state;
    reg [WIDTH-1:0] data_reg_stage3;
    reg src_valid_stage3;
    
    // Combinational logic signals
    reg [1:0] next_state;
    reg data_out_next;
    reg dst_valid_next;
    
    // Source domain logic - data capture and toggle generation
    always @(posedge src_clk or posedge rst) begin
        if (rst) begin
            toggle_src <= 1'b0;
            data_reg <= {WIDTH{1'b0}};
        end else if (src_valid) begin
            toggle_src <= ~toggle_src;
            data_reg <= data_in;
        end
    end
    
    // Destination domain logic - Stage 1
    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            toggle_dst_sync_stage1 <= 2'b00;
            data_reg_stage1 <= {WIDTH{1'b0}};
            src_valid_stage1 <= 1'b0;
        end else begin
            toggle_dst_sync_stage1 <= {toggle_dst_sync_stage1[0], toggle_src};
            data_reg_stage1 <= data_reg;
            src_valid_stage1 <= src_valid;
        end
    end
    
    // Destination domain logic - Stage 2
    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            toggle_dst_sync_stage2 <= 2'b00;
            data_reg_stage2 <= {WIDTH{1'b0}};
            src_valid_stage2 <= 1'b0;
        end else begin
            toggle_dst_sync_stage2 <= toggle_dst_sync_stage1;
            data_reg_stage2 <= data_reg_stage1;
            src_valid_stage2 <= src_valid_stage1;
        end
    end
    
    // Combinational logic for next state and outputs
    always @(*) begin
        // Default values
        next_state = state;
        data_out_next = data_out;
        dst_valid_next = 1'b0;
        
        // Next state logic
        case (state)
            IDLE: next_state = (toggle_dst_sync_stage2[1] != toggle_dst_sync_stage2[0]) ? SYNC1 : IDLE;
            SYNC1: next_state = SYNC2;
            SYNC2: next_state = VALID;
            VALID: next_state = IDLE;
            default: next_state = IDLE;
        endcase
        
        // Output logic
        if (state == VALID) begin
            data_out_next = data_reg_stage3;
            dst_valid_next = 1'b1;
        end
    end
    
    // Destination domain logic - Stage 3 (sequential)
    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            data_reg_stage3 <= {WIDTH{1'b0}};
            src_valid_stage3 <= 1'b0;
            data_out <= {WIDTH{1'b0}};
            dst_valid <= 1'b0;
        end else begin
            state <= next_state;
            data_reg_stage3 <= data_reg_stage2;
            src_valid_stage3 <= src_valid_stage2;
            data_out <= data_out_next;
            dst_valid <= dst_valid_next;
        end
    end
endmodule