//SystemVerilog
module scan_reg (
    input wire clk,
    input wire rst_n,
    input wire [7:0] parallel_data,
    input wire scan_in,
    input wire scan_en,
    input wire load,
    input wire valid_in,
    output reg [7:0] data_out,
    output wire scan_out,
    output reg valid_out
);
    // Pipeline stage 1 registers
    reg [7:0] stage1_data;
    reg stage1_scan_in;
    reg stage1_scan_en;
    reg stage1_load;
    reg stage1_valid;
    
    // Pipeline stage 2 registers 
    reg [7:0] stage2_data;
    reg stage2_valid;
    
    // Pipeline stage 3 registers (added)
    reg [7:0] stage3_data;
    reg stage3_valid;
    
    // Stage 1: Input registration and control signal processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data <= 8'b0;
            stage1_scan_in <= 1'b0;
            stage1_scan_en <= 1'b0;
            stage1_load <= 1'b0;
            stage1_valid <= 1'b0;
        end
        else begin
            stage1_data <= parallel_data;
            stage1_scan_in <= scan_in;
            stage1_scan_en <= scan_en;
            stage1_load <= load;
            stage1_valid <= valid_in;
        end
    end
    
    // Stage 2: Data manipulation calculation (converted to sequential)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_data <= 8'b0;
            stage2_valid <= 1'b0;
        end
        else begin
            if (stage1_scan_en)
                stage2_data <= {data_out[6:0], stage1_scan_in};
            else if (stage1_load)
                stage2_data <= stage1_data;
            else
                stage2_data <= data_out;
                
            stage2_valid <= stage1_valid;
        end
    end
    
    // Stage 3: Intermediate processing (new stage)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_data <= 8'b0;
            stage3_valid <= 1'b0;
        end
        else begin
            stage3_data <= stage2_data;
            stage3_valid <= stage2_valid;
        end
    end
    
    // Stage 4: Output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'b0;
            valid_out <= 1'b0;
        end
        else begin
            data_out <= stage3_data;
            valid_out <= stage3_valid;
        end
    end
    
    // Scan output taken from the final output
    assign scan_out = data_out[7];
    
endmodule