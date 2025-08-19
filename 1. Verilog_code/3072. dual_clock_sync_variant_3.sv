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
    localparam IDLE=0, SYNC=1, SYNC2=2, VALID=3, VALID2=4, WAIT=5;
    reg [2:0] src_state, src_next;
    reg [2:0] dst_state, dst_next;
    reg req, ack;
    reg req_sync1, req_sync2, req_sync3;
    reg ack_sync1, ack_sync2, ack_sync3;
    reg [WIDTH-1:0] data_buf, data_buf2;
    
    // Source clock domain
    always @(posedge src_clk or posedge rst) begin
        if (rst) begin
            src_state <= IDLE;
            data_buf <= 0;
            data_buf2 <= 0;
            req <= 1'b0;
            ack_sync1 <= 1'b0;
            ack_sync2 <= 1'b0;
            ack_sync3 <= 1'b0;
        end else begin
            src_state <= src_next;
            ack_sync1 <= ack;
            ack_sync2 <= ack_sync1;
            ack_sync3 <= ack_sync2;
            
            case (src_state)
                IDLE: if (data_valid) data_buf <= data_in;
                SYNC: data_buf2 <= data_buf;
                SYNC2: req <= 1'b1;
                WAIT: if (ack_sync3) req <= 1'b0;
            endcase
        end
    end
    
    // Destination clock domain
    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            dst_state <= IDLE;
            data_out <= 0;
            sync_done <= 1'b0;
            req_sync1 <= 1'b0;
            req_sync2 <= 1'b0;
            req_sync3 <= 1'b0;
            ack <= 1'b0;
        end else begin
            dst_state <= dst_next;
            req_sync1 <= req;
            req_sync2 <= req_sync1;
            req_sync3 <= req_sync2;
            
            case (dst_state)
                VALID2: begin
                    data_out <= data_buf2;
                    sync_done <= 1'b1;
                    ack <= 1'b1;
                end
                WAIT: begin
                    sync_done <= 1'b0;
                    if (!req_sync3) ack <= 1'b0;
                end
                default: sync_done <= 1'b0;
            endcase
        end
    end
    
    // Source state machine
    always @(*) begin
        case (src_state)
            IDLE: src_next = data_valid ? SYNC : IDLE;
            SYNC: src_next = SYNC2;
            SYNC2: src_next = WAIT;
            WAIT: src_next = ack_sync3 ? (req ? WAIT : IDLE) : WAIT;
            default: src_next = IDLE;
        endcase
    end
    
    // Destination state machine
    always @(*) begin
        case (dst_state)
            IDLE: dst_next = req_sync3 ? VALID : IDLE;
            VALID: dst_next = VALID2;
            VALID2: dst_next = WAIT;
            WAIT: dst_next = !req_sync3 ? IDLE : WAIT;
            default: dst_next = IDLE;
        endcase
    end
endmodule