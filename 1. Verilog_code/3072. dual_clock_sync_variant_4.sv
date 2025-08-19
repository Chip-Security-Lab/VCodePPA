//SystemVerilog
module dual_clock_sync #(
    parameter WIDTH = 8
)(
    input wire src_clk, dst_clk, rst,
    input wire [WIDTH-1:0] data_in,
    input wire data_valid,
    output reg [WIDTH-1:0] data_out,
    output reg sync_done
);
    localparam IDLE=0, SYNC=1, VALID=2, WAIT=3;
    
    // Source domain pipeline registers
    reg [1:0] src_state_stage1, src_state_stage2;
    reg [WIDTH-1:0] data_buf_stage1, data_buf_stage2;
    reg req_stage1, req_stage2;
    reg ack_sync1_stage1, ack_sync1_stage2;
    reg ack_sync2_stage1, ack_sync2_stage2;
    
    // Destination domain pipeline registers
    reg [1:0] dst_state_stage1, dst_state_stage2;
    reg [WIDTH-1:0] data_out_stage1, data_out_stage2;
    reg sync_done_stage1, sync_done_stage2;
    reg req_sync1_stage1, req_sync1_stage2;
    reg req_sync2_stage1, req_sync2_stage2;
    reg ack_stage1, ack_stage2;
    
    // Parallel prefix subtractor signals
    wire [1:0] sub_a = {1'b0, data_valid};
    wire [1:0] sub_b = {1'b0, ack_sync2_stage1};
    wire [1:0] sub_diff;
    wire sub_borrow;
    
    // Parallel prefix subtractor implementation
    wire [1:0] g = sub_a & ~sub_b;
    wire [1:0] p = sub_a ^ sub_b;
    wire [1:0] c;
    
    assign c[0] = 1'b0;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign sub_diff = p ^ {c[0], c[1]};
    assign sub_borrow = c[1];
    
    // Source clock domain pipeline
    always @(posedge src_clk or posedge rst) begin
        if (rst) begin
            src_state_stage1 <= IDLE;
            data_buf_stage1 <= 0;
            req_stage1 <= 1'b0;
            ack_sync1_stage1 <= 1'b0;
            ack_sync2_stage1 <= 1'b0;
            
            src_state_stage2 <= IDLE;
            data_buf_stage2 <= 0;
            req_stage2 <= 1'b0;
            ack_sync1_stage2 <= 1'b0;
            ack_sync2_stage2 <= 1'b0;
        end else begin
            // Stage 1
            if (src_state_stage1 == IDLE && data_valid)
                data_buf_stage1 <= data_in;
            ack_sync1_stage1 <= ack_stage2;
            ack_sync2_stage1 <= ack_sync1_stage2;
            
            // Stage 2
            src_state_stage2 <= src_state_stage1;
            data_buf_stage2 <= data_buf_stage1;
            ack_sync1_stage2 <= ack_sync1_stage1;
            ack_sync2_stage2 <= ack_sync2_stage1;
            
            if (src_state_stage1 == SYNC)
                req_stage1 <= 1'b1;
            else if (src_state_stage1 == WAIT && ack_sync2_stage1)
                req_stage1 <= 1'b0;
            req_stage2 <= req_stage1;
        end
    end
    
    // Destination clock domain pipeline
    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            dst_state_stage1 <= IDLE;
            data_out_stage1 <= 0;
            sync_done_stage1 <= 1'b0;
            req_sync1_stage1 <= 1'b0;
            req_sync2_stage1 <= 1'b0;
            ack_stage1 <= 1'b0;
            
            dst_state_stage2 <= IDLE;
            data_out_stage2 <= 0;
            sync_done_stage2 <= 1'b0;
            req_sync1_stage2 <= 1'b0;
            req_sync2_stage2 <= 1'b0;
            ack_stage2 <= 1'b0;
        end else begin
            // Stage 1
            req_sync1_stage1 <= req_stage2;
            req_sync2_stage1 <= req_sync1_stage2;
            
            // Stage 2
            dst_state_stage2 <= dst_state_stage1;
            req_sync1_stage2 <= req_sync1_stage1;
            req_sync2_stage2 <= req_sync2_stage1;
            
            if (dst_state_stage1 == VALID) begin
                data_out_stage1 <= data_buf_stage2;
                sync_done_stage1 <= 1'b1;
                ack_stage1 <= 1'b1;
            end else begin
                sync_done_stage1 <= 1'b0;
                if (dst_state_stage1 == WAIT && !req_sync2_stage1)
                    ack_stage1 <= 1'b0;
            end
            
            data_out_stage2 <= data_out_stage1;
            sync_done_stage2 <= sync_done_stage1;
            ack_stage2 <= ack_stage1;
        end
    end
    
    // Source state machine
    always @(*) begin
        case (src_state_stage1)
            IDLE: src_state_stage1 = data_valid ? SYNC : IDLE;
            SYNC: src_state_stage1 = WAIT;
            WAIT: src_state_stage1 = ack_sync2_stage1 ? (req_stage1 ? WAIT : IDLE) : WAIT;
            default: src_state_stage1 = IDLE;
        endcase
    end
    
    // Destination state machine
    always @(*) begin
        case (dst_state_stage1)
            IDLE: dst_state_stage1 = req_sync2_stage1 ? VALID : IDLE;
            VALID: dst_state_stage1 = WAIT;
            WAIT: dst_state_stage1 = !req_sync2_stage1 ? IDLE : WAIT;
            default: dst_state_stage1 = IDLE;
        endcase
    end
    
    // Output assignments
    assign data_out = data_out_stage2;
    assign sync_done = sync_done_stage2;
endmodule