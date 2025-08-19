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
    // One-hot state encoding
    localparam IDLE = 4'b0001,
               SYNC = 4'b0010,
               VALID = 4'b0100,
               WAIT = 4'b1000;
    
    reg [3:0] src_state, src_next;
    reg [3:0] dst_state, dst_next;
    reg req, ack;
    reg req_sync1, req_sync2;
    reg ack_sync1, ack_sync2;
    reg [WIDTH-1:0] data_buf;
    
    // Source clock domain
    always @(posedge src_clk or posedge rst)
        if (rst) begin
            src_state <= IDLE;
            data_buf <= 0;
            req <= 1'b0;
            ack_sync1 <= 1'b0;
            ack_sync2 <= 1'b0;
        end else begin
            src_state <= src_next;
            if (src_state[0] && data_valid)
                data_buf <= data_in;
            
            ack_sync1 <= ack;
            ack_sync2 <= ack_sync1;
            
            if (src_state[1])
                req <= 1'b1;
            else if (src_state[3] && ack_sync2)
                req <= 1'b0;
        end
    
    // Destination clock domain
    always @(posedge dst_clk or posedge rst)
        if (rst) begin
            dst_state <= IDLE;
            data_out <= 0;
            sync_done <= 1'b0;
            req_sync1 <= 1'b0;
            req_sync2 <= 1'b0;
            ack <= 1'b0;
        end else begin
            dst_state <= dst_next;
            
            req_sync1 <= req;
            req_sync2 <= req_sync1;
            
            if (dst_state[2]) begin
                data_out <= data_buf;
                sync_done <= 1'b1;
                ack <= 1'b1;
            end else begin
                sync_done <= 1'b0;
                if (dst_state[3] && !req_sync2)
                    ack <= 1'b0;
            end
        end
    
    // Source state machine
    always @(*)
        case (1'b1)
            src_state[0]: src_next = data_valid ? SYNC : IDLE;
            src_state[1]: src_next = WAIT;
            src_state[3]: src_next = ack_sync2 ? (req ? WAIT : IDLE) : WAIT;
            default: src_next = IDLE;
        endcase
    
    // Destination state machine
    always @(*)
        case (1'b1)
            dst_state[0]: dst_next = req_sync2 ? VALID : IDLE;
            dst_state[2]: dst_next = WAIT;
            dst_state[3]: dst_next = !req_sync2 ? IDLE : WAIT;
            default: dst_next = IDLE;
        endcase
endmodule