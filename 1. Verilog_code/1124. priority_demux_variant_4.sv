//SystemVerilog
module priority_demux (
    input wire clk,                      // Clock signal
    input wire rst_n,                    // Active-low reset
    input wire data_in,                  // Input data
    input wire [2:0] pri_select,         // Priority selection
    output reg [7:0] dout                // Output channels
);
    // Internal pipeline registers for data path
    reg data_in_r;
    reg [2:0] pri_select_r;
    
    // First pipeline stage: register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_r <= 1'b0;
            pri_select_r <= 3'b0;
        end else begin
            data_in_r <= data_in;
            pri_select_r <= pri_select;
        end
    end
    
    // Second pipeline stage: decoded priority signals
    reg pri_high, pri_mid, pri_low, pri_default;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pri_high <= 1'b0;
            pri_mid <= 1'b0;
            pri_low <= 1'b0;
            pri_default <= 1'b0;
        end else begin
            pri_high <= pri_select_r[2];
            pri_mid <= pri_select_r[1] & ~pri_select_r[2];
            pri_low <= pri_select_r[0] & ~pri_select_r[2] & ~pri_select_r[1];
            pri_default <= ~|pri_select_r;
        end
    end
    
    // Third pipeline stage: data path logic
    reg data_path_r;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_path_r <= 1'b0;
        end else begin
            data_path_r <= data_in_r;
        end
    end
    
    // Final stage: output demux logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= 8'b0;
        end else begin
            dout <= 8'b0; // Default all outputs to zero
            
            if (pri_high)
                dout[7:4] <= {4{data_path_r}};
            else if (pri_mid)
                dout[3:2] <= {2{data_path_r}};
            else if (pri_low)
                dout[1] <= data_path_r;
            else if (pri_default)
                dout[0] <= data_path_r;
        end
    end
endmodule