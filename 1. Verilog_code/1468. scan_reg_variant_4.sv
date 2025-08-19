//SystemVerilog
module scan_reg(
    input clk, rst_n,
    input [7:0] parallel_data,
    input scan_in, scan_en, load,
    output reg [7:0] data_out,
    output scan_out
);
    // Direct input registers to reduce input-to-register delay
    reg scan_en_r, load_r, scan_in_r;
    reg [7:0] parallel_data_r;
    
    // First stage input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scan_en_r <= 1'b0;
            load_r <= 1'b0;
            scan_in_r <= 1'b0;
            parallel_data_r <= 8'b0;
        end else begin
            scan_en_r <= scan_en;
            load_r <= load;
            scan_in_r <= scan_in;
            parallel_data_r <= parallel_data;
        end
    end
    
    // Buffered control signals derived from registered inputs
    wire scan_en_buf1, scan_en_buf2;
    wire load_buf1, load_buf2;
    
    // Distribute control signals with direct combinational logic
    assign scan_en_buf1 = scan_en_r;
    assign scan_en_buf2 = scan_en_r;
    assign load_buf1 = load_r;
    assign load_buf2 = load_r;
    
    // Main data processing logic - lower half
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out[3:0] <= 4'b0;
        end else if (scan_en_buf1) begin
            data_out[3:0] <= {data_out[2:0], scan_in_r};
        end else if (load_buf1) begin
            data_out[3:0] <= parallel_data_r[3:0];
        end
    end
    
    // Main data processing logic - upper half
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out[7:4] <= 4'b0;
        end else if (scan_en_buf2) begin
            data_out[7:4] <= {data_out[6:4], data_out[3]};
        end else if (load_buf2) begin
            data_out[7:4] <= parallel_data_r[7:4];
        end
    end
    
    // Output logic
    reg scan_out_int;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            scan_out_int <= 1'b0;
        else
            scan_out_int <= data_out[7];
    end
    
    assign scan_out = scan_out_int;
endmodule