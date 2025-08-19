//SystemVerilog
module fault_tolerant_icmu (
    input clk_a, clk_b, reset_n,
    input [7:0] irq_a, irq_b,
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
    reg [1:0] next_error_status;
    
    // Clock domain A
    always @(posedge clk_a or negedge reset_n) begin
        if (!reset_n) begin
            pending_a <= 8'h00;
            masked_a <= 8'h00;
            int_id_a <= 3'd0;
            int_valid_a <= 1'b0;
            error_status[0] <= 1'b0;
        end else begin
            // Update pending and masked interrupts
            pending_a <= pending_a | irq_a;
            masked_a <= pending_a & mask;
            
            // Determine next interrupt ID and validity
            next_id_a = int_id_a;
            next_valid_a = int_valid_a;
            
            if (!int_valid_a) begin
                if (|masked_a) begin
                    next_id_a = encode_id(masked_a);
                    next_valid_a = 1'b1;
                    pending_a[next_id_a] <= 1'b0;
                end
            end else begin
                if (!masked_a[int_id_a]) begin
                    next_valid_a = 1'b0;
                end
            end
            
            // Update outputs
            int_id_a <= next_id_a;
            int_valid_a <= next_valid_a;
            
            // Error detection and clearing
            next_error_status[0] = error_status[0];
            if (int_valid_a && int_valid_b && (int_id_a != int_id_b)) begin
                next_error_status[0] = 1'b1;
            end
            if (err_clear) begin
                next_error_status[0] = 1'b0;
            end
            error_status[0] <= next_error_status[0];
        end
    end
    
    // Clock domain B
    always @(posedge clk_b or negedge reset_n) begin
        if (!reset_n) begin
            pending_b <= 8'h00;
            masked_b <= 8'h00;
            int_id_b <= 3'd0;
            int_valid_b <= 1'b0;
            error_status[1] <= 1'b0;
        end else begin
            // Update pending and masked interrupts
            pending_b <= pending_b | irq_b;
            masked_b <= pending_b & mask;
            
            // Determine next interrupt ID and validity
            next_id_b = int_id_b;
            next_valid_b = int_valid_b;
            
            if (!int_valid_b) begin
                if (|masked_b) begin
                    next_id_b = encode_id(masked_b);
                    next_valid_b = 1'b1;
                    pending_b[next_id_b] <= 1'b0;
                end
            end else begin
                if (!masked_b[int_id_b]) begin
                    next_valid_b = 1'b0;
                end
            end
            
            // Update outputs
            int_id_b <= next_id_b;
            int_valid_b <= next_valid_b;
            
            // Error detection and clearing
            next_error_status[1] = error_status[1];
            if (int_valid_a && int_valid_b && (int_id_a != int_id_b)) begin
                next_error_status[1] = 1'b1;
            end
            if (err_clear) begin
                next_error_status[1] = 1'b0;
            end
            error_status[1] <= next_error_status[1];
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