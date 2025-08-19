//SystemVerilog
module async_reset_ring_counter(
    input wire clk,
    input wire rst_n,    // Active-low reset
    input wire req,      // Request signal
    output reg ack,      // Acknowledge signal
    output reg [3:0] q
);
    // Pipeline stage signals
    reg req_stage1, req_stage2;
    reg req_edge_stage1, req_edge_stage2;
    reg [3:0] q_next;
    reg transfer_done_stage1, transfer_done_stage2;
    reg ack_stage1;
    
    // Stage 1: Request edge detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_stage1 <= 1'b0;
            req_edge_stage1 <= 1'b0;
        end
        else begin
            req_stage1 <= req;
            req_edge_stage1 <= req & ~req_stage1;
        end
    end
    
    // Stage 2: Calculate next counter value and control signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_stage2 <= 1'b0;
            req_edge_stage2 <= 1'b0;
            q_next <= 4'b0001;
            transfer_done_stage1 <= 1'b0;
            ack_stage1 <= 1'b0;
        end
        else begin
            req_stage2 <= req_stage1;
            req_edge_stage2 <= req_edge_stage1;
            
            if (req_edge_stage1 && !transfer_done_stage1) begin
                q_next <= {q[2:0], q[3]};  // Prepare next counter value
                ack_stage1 <= 1'b1;
                transfer_done_stage1 <= 1'b1;
            end
            else if (!req_stage1 && transfer_done_stage1) begin
                ack_stage1 <= 1'b0;
                transfer_done_stage1 <= 1'b0;
            end
        end
    end
    
    // Stage 3: Update output registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 4'b0001;
            ack <= 1'b0;
            transfer_done_stage2 <= 1'b0;
        end
        else begin
            transfer_done_stage2 <= transfer_done_stage1;
            
            if (req_edge_stage2 && !transfer_done_stage2) begin
                q <= q_next;
                ack <= ack_stage1;
            end
            else if (!req_stage2 && transfer_done_stage2) begin
                ack <= ack_stage1;
            end
        end
    end
endmodule