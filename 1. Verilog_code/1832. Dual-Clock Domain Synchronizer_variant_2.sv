//SystemVerilog
module cross_domain_sync #(parameter BUS_WIDTH = 16) (
    // Source domain signals
    input  wire                  src_clk,
    input  wire                  src_rst,
    input  wire [BUS_WIDTH-1:0]  src_data,
    input  wire                  src_valid,
    output reg                   src_ready,
    
    // Destination domain signals
    input  wire                  dst_clk,
    input  wire                  dst_rst,
    output reg  [BUS_WIDTH-1:0]  dst_data,
    output reg                   dst_valid,
    input  wire                  dst_ready
);
    // Sync flags between domains
    reg src_toggle_flag;
    reg [2:0] dst_sync_flag;
    
    // Source domain state encoding and lookup table
    localparam [1:0] SRC_IDLE = 2'd0,
                     SRC_WAIT = 2'd1,
                     SRC_DONE = 2'd2;
    
    reg [1:0] src_state, src_next_state;
    reg src_toggle_next;
    reg src_ready_next;
    
    // Source domain state transition lookup table
    always @(*) begin
        // Default values to prevent latches
        src_next_state = src_state;
        src_toggle_next = src_toggle_flag;
        src_ready_next = src_ready;
        
        case (src_state)
            SRC_IDLE: begin
                if (src_valid && src_ready) begin
                    src_next_state = SRC_WAIT;
                    src_toggle_next = ~src_toggle_flag;
                    src_ready_next = 1'b0;
                end
            end
            
            SRC_WAIT: begin
                if (dst_sync_flag[2] == src_toggle_flag) begin
                    src_next_state = SRC_IDLE;
                    src_ready_next = 1'b1;
                end
            end
            
            default: begin
                src_next_state = SRC_IDLE;
            end
        endcase
    end
    
    // Source domain state register
    always @(posedge src_clk or posedge src_rst) begin
        if (src_rst) begin
            src_state <= SRC_IDLE;
            src_toggle_flag <= 1'b0;
            src_ready <= 1'b1;
        end else begin
            src_state <= src_next_state;
            src_toggle_flag <= src_toggle_next;
            src_ready <= src_ready_next;
        end
    end
    
    // Destination domain state encoding and lookup table
    localparam [1:0] DST_IDLE = 2'd0,
                     DST_VALID = 2'd1;
    
    reg [1:0] dst_state, dst_next_state;
    reg [2:0] dst_sync_next;
    reg dst_valid_next;
    reg [BUS_WIDTH-1:0] dst_data_next;
    
    // Destination domain state transition lookup table
    always @(*) begin
        // Default values to prevent latches
        dst_next_state = dst_state;
        dst_sync_next = {dst_sync_flag[1:0], src_toggle_flag};
        dst_valid_next = dst_valid;
        dst_data_next = dst_data;
        
        case (dst_state)
            DST_IDLE: begin
                if (dst_sync_flag[2] != dst_sync_flag[1]) begin
                    dst_next_state = DST_VALID;
                    dst_data_next = src_data;
                    dst_valid_next = 1'b1;
                end
            end
            
            DST_VALID: begin
                if (dst_ready) begin
                    dst_next_state = DST_IDLE;
                    dst_valid_next = 1'b0;
                end
            end
            
            default: begin
                dst_next_state = DST_IDLE;
            end
        endcase
    end
    
    // Destination domain state register
    always @(posedge dst_clk or posedge dst_rst) begin
        if (dst_rst) begin
            dst_state <= DST_IDLE;
            dst_sync_flag <= 3'b000;
            dst_valid <= 1'b0;
            dst_data <= {BUS_WIDTH{1'b0}};
        end else begin
            dst_state <= dst_next_state;
            dst_sync_flag <= dst_sync_next;
            dst_valid <= dst_valid_next;
            dst_data <= dst_data_next;
        end
    end
endmodule