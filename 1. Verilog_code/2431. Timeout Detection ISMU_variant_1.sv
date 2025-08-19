//SystemVerilog
module timeout_ismu(
    input clk, rst_n,
    input [3:0] irq_in,
    input [3:0] irq_mask,
    input [7:0] timeout_val,
    output reg [3:0] irq_out,
    output reg timeout_flag
);
    // Counter registers and buffers
    reg [7:0] counter [3:0];
    reg [7:0] counter_buf0 [1:0];  // Buffer for counters 0,1
    reg [7:0] counter_buf1 [1:0];  // Buffer for counters 2,3
    
    // Index registers and buffers
    reg [1:0] i_buf0;              // Index buffer for first half logic
    reg [1:0] i_buf1;              // Index buffer for second half logic
    
    // Timeout value buffers to reduce fanout
    reg [7:0] timeout_val_buf0;    // For first half of counters
    reg [7:0] timeout_val_buf1;    // For second half of counters
    
    integer i;
    
    // Buffer registers for timeout flag generation
    reg timeout_cond0, timeout_cond1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all buffers and outputs
            timeout_val_buf0 <= 8'h0;
            timeout_val_buf1 <= 8'h0;
            i_buf0 <= 2'h0;
            i_buf1 <= 2'h0;
            timeout_cond0 <= 1'b0;
            timeout_cond1 <= 1'b0;
            
            // Reset main registers
            irq_out <= 4'h0;
            timeout_flag <= 1'b0;
            for (i = 0; i < 4; i = i + 1) begin
                counter[i] <= 8'h0;
                if (i < 2)
                    counter_buf0[i] <= 8'h0;
                else
                    counter_buf1[i-2] <= 8'h0;
            end
        end else begin
            // Buffer timeout value to reduce fanout
            timeout_val_buf0 <= timeout_val;
            timeout_val_buf1 <= timeout_val;
            
            // Reset timeout flag each cycle
            timeout_flag <= 1'b0;
            timeout_cond0 <= 1'b0;
            timeout_cond1 <= 1'b0;
            
            // Process first two counters
            for (i = 0; i < 2; i = i + 1) begin
                i_buf0 <= i[1:0];
                if (irq_in[i] && !irq_mask[i]) begin
                    if (counter[i] < timeout_val_buf0)
                        counter[i] <= counter[i] + 8'h1;
                    else begin
                        timeout_cond0 <= 1'b1;
                        irq_out[i] <= 1'b1;
                    end
                    counter_buf0[i] <= counter[i];
                end else begin
                    counter[i] <= 8'h0;
                    counter_buf0[i] <= 8'h0;
                    irq_out[i] <= 1'b0;
                end
            end
            
            // Process second two counters
            for (i = 2; i < 4; i = i + 1) begin
                i_buf1 <= i[1:0];
                if (irq_in[i] && !irq_mask[i]) begin
                    if (counter[i] < timeout_val_buf1)
                        counter[i] <= counter[i] + 8'h1;
                    else begin
                        timeout_cond1 <= 1'b1;
                        irq_out[i] <= 1'b1;
                    end
                    counter_buf1[i-2] <= counter[i];
                end else begin
                    counter[i] <= 8'h0;
                    counter_buf1[i-2] <= 8'h0;
                    irq_out[i] <= 1'b0;
                end
            end
            
            // Generate timeout flag from buffered conditions
            timeout_flag <= timeout_cond0 || timeout_cond1;
        end
    end
endmodule