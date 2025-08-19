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
    localparam IDLE = 2'b00, SYNC = 2'b01, VALID = 2'b10, WAIT = 2'b11;
    reg [1:0] src_state, src_next;
    reg [1:0] dst_state, dst_next;
    reg req, ack;
    reg req_sync1, req_sync2;
    reg ack_sync1, ack_sync2;
    reg [WIDTH-1:0] data_buf;

    // Source clock domain
    always @(posedge src_clk or posedge rst) begin
        if (rst) begin
            src_state <= IDLE;
            data_buf <= 0;
            req <= 1'b0;
            ack_sync1 <= 1'b0;
            ack_sync2 <= 1'b0;
        end else begin
            src_state <= src_next;
            if (src_state == IDLE && data_valid) begin
                data_buf <= data_in;
            end

            // Synchronize ack to src domain
            {ack_sync2, ack_sync1} <= {ack_sync1, ack};
            
            req <= (src_state == SYNC) ? 1'b1 : 
                    (src_state == WAIT && ack_sync2) ? 1'b0 : req;
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
            ack <= 1'b0;
        end else begin
            dst_state <= dst_next;

            // Synchronize req to dst domain
            {req_sync2, req_sync1} <= {req_sync1, req};

            if (dst_state == VALID) begin
                data_out <= data_buf;
                sync_done <= 1'b1;
                ack <= 1'b1;
            end else begin
                sync_done <= 1'b0;
                ack <= (dst_state == WAIT && !req_sync2) ? 1'b0 : ack;
            end
        end
    end

    // Source state machine
    always @(*) begin
        case (src_state)
            IDLE: src_next = data_valid ? SYNC : IDLE;
            SYNC: src_next = WAIT;
            WAIT: src_next = ack_sync2 ? (req ? WAIT : IDLE) : WAIT;
            default: src_next = IDLE;
        endcase
    end

    // Destination state machine
    always @(*) begin
        case (dst_state)
            IDLE: dst_next = req_sync2 ? VALID : IDLE;
            VALID: dst_next = WAIT;
            WAIT: dst_next = !req_sync2 ? IDLE : WAIT;
            default: dst_next = IDLE;
        endcase
    end
endmodule