//SystemVerilog
module fault_tolerant_icmu (
    input clk_a, clk_b, reset_n,
    input [7:0] irq_a, irq_b,
    input ready_a, ready_b,
    output reg [2:0] int_id_a, int_id_b,
    output reg int_valid_a, int_valid_b,
    output reg [1:0] error_status,
    input err_clear
);

    reg [7:0] pending_a, pending_b;
    reg [7:0] masked_a, masked_b;
    reg [7:0] mask = 8'hFF;
    reg error_detected;
    reg [2:0] next_id_a, next_id_b;
    reg next_valid_a, next_valid_b;

    // Buffer registers for high fanout signals
    reg int_valid_a_buf1, int_valid_a_buf2;
    reg int_valid_b_buf1, int_valid_b_buf2;
    reg [1:0] error_status_buf1, error_status_buf2;
    reg [7:0] pending_a_buf1, pending_a_buf2;
    reg [7:0] pending_b_buf1, pending_b_buf2;

    // Clock domain A
    always @(posedge clk_a or negedge reset_n) begin
        if (!reset_n) begin
            pending_a <= 8'h00;
            pending_a_buf1 <= 8'h00;
            pending_a_buf2 <= 8'h00;
            masked_a <= 8'h00;
            int_id_a <= 3'd0;
            int_valid_a <= 1'b0;
            int_valid_a_buf1 <= 1'b0;
            int_valid_a_buf2 <= 1'b0;
            next_id_a <= 3'd0;
            next_valid_a <= 1'b0;
            error_status[0] <= 1'b0;
            error_status_buf1[0] <= 1'b0;
            error_status_buf2[0] <= 1'b0;
        end else begin
            pending_a <= pending_a | irq_a;
            pending_a_buf1 <= pending_a;
            pending_a_buf2 <= pending_a_buf1;
            masked_a <= pending_a_buf2 & mask;
            
            if (!next_valid_a && |masked_a) begin
                next_id_a <= encode_id(masked_a);
                next_valid_a <= 1'b1;
                pending_a[next_id_a] <= 1'b0;
            end
            
            if (int_valid_a_buf2 && ready_a) begin
                int_valid_a <= 1'b0;
                int_valid_a_buf1 <= 1'b0;
                int_valid_a_buf2 <= 1'b0;
            end
            
            if (!int_valid_a_buf2 && next_valid_a) begin
                int_id_a <= next_id_a;
                int_valid_a <= 1'b1;
                int_valid_a_buf1 <= 1'b1;
                int_valid_a_buf2 <= 1'b1;
                next_valid_a <= 1'b0;
            end
            
            if (int_valid_a_buf2 && !masked_a[int_id_a]) begin
                int_valid_a <= 1'b0;
                int_valid_a_buf1 <= 1'b0;
                int_valid_a_buf2 <= 1'b0;
            end
            
            if (int_valid_a_buf2 && int_valid_b_buf2 && (int_id_a != int_id_b)) begin
                error_status[0] <= 1'b1;
                error_status_buf1[0] <= 1'b1;
                error_status_buf2[0] <= 1'b1;
            end
                
            if (err_clear) begin
                error_status[0] <= 1'b0;
                error_status_buf1[0] <= 1'b0;
                error_status_buf2[0] <= 1'b0;
            end
        end
    end
    
    // Clock domain B
    always @(posedge clk_b or negedge reset_n) begin
        if (!reset_n) begin
            pending_b <= 8'h00;
            pending_b_buf1 <= 8'h00;
            pending_b_buf2 <= 8'h00;
            masked_b <= 8'h00;
            int_id_b <= 3'd0;
            int_valid_b <= 1'b0;
            int_valid_b_buf1 <= 1'b0;
            int_valid_b_buf2 <= 1'b0;
            next_id_b <= 3'd0;
            next_valid_b <= 1'b0;
            error_status[1] <= 1'b0;
            error_status_buf1[1] <= 1'b0;
            error_status_buf2[1] <= 1'b0;
        end else begin
            pending_b <= pending_b | irq_b;
            pending_b_buf1 <= pending_b;
            pending_b_buf2 <= pending_b_buf1;
            masked_b <= pending_b_buf2 & mask;
            
            if (!next_valid_b && |masked_b) begin
                next_id_b <= encode_id(masked_b);
                next_valid_b <= 1'b1;
                pending_b[next_id_b] <= 1'b0;
            end
            
            if (int_valid_b_buf2 && ready_b) begin
                int_valid_b <= 1'b0;
                int_valid_b_buf1 <= 1'b0;
                int_valid_b_buf2 <= 1'b0;
            end
            
            if (!int_valid_b_buf2 && next_valid_b) begin
                int_id_b <= next_id_b;
                int_valid_b <= 1'b1;
                int_valid_b_buf1 <= 1'b1;
                int_valid_b_buf2 <= 1'b1;
                next_valid_b <= 1'b0;
            end
            
            if (int_valid_b_buf2 && !masked_b[int_id_b]) begin
                int_valid_b <= 1'b0;
                int_valid_b_buf1 <= 1'b0;
                int_valid_b_buf2 <= 1'b0;
            end
            
            if (int_valid_a_buf2 && int_valid_b_buf2 && (int_id_a != int_id_b)) begin
                error_status[1] <= 1'b1;
                error_status_buf1[1] <= 1'b1;
                error_status_buf2[1] <= 1'b1;
            end
                
            if (err_clear) begin
                error_status[1] <= 1'b0;
                error_status_buf1[1] <= 1'b0;
                error_status_buf2[1] <= 1'b0;
            end
        end
    end
    
    function [2:0] encode_id;
        input [7:0] irqs;
        reg [2:0] result;
        integer i;
        begin
            result = 3'd0;
            for (i = 7; i >= 0; i=i-1)
                if (irqs[i]) result = i[2:0];
            encode_id = result;
        end
    endfunction

endmodule