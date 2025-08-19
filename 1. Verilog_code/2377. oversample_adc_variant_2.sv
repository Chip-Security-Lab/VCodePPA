//SystemVerilog
/* IEEE 1364-2005 Verilog */
module oversample_adc (
    input wire clk,
    input wire adc_in,
    
    // AXI-Stream master interface
    output wire [7:0] m_axis_tdata,
    output wire m_axis_tvalid,
    input wire m_axis_tready,
    output wire m_axis_tlast
);

    reg [2:0] sum;
    reg [7:0] adc_result;
    reg data_valid;
    reg [2:0] sample_counter;
    
    // Sample accumulation logic
    always @(posedge clk) begin
        if (sample_counter == 3'b111) begin
            sum <= adc_in;
            sample_counter <= 3'b000;
        end else begin
            sum <= sum + adc_in;
            sample_counter <= sample_counter + 1'b1;
        end
    end
    
    // Barrel shifter implementation
    wire [7:0] shifted_data;
    
    // Implement barrel shifter for shift by 5
    assign shifted_data[0] = 1'b0;
    assign shifted_data[1] = 1'b0;
    assign shifted_data[2] = 1'b0;
    assign shifted_data[3] = 1'b0;
    assign shifted_data[4] = 1'b0;
    assign shifted_data[5] = sum[0];
    assign shifted_data[6] = sum[1];
    assign shifted_data[7] = sum[2];
    
    // Output data generation
    always @(posedge clk) begin
        if (sample_counter == 3'b111) begin
            adc_result <= shifted_data;
            data_valid <= 1'b1;
        end else if (m_axis_tready && data_valid) begin
            data_valid <= 1'b0;
        end
    end
    
    // AXI-Stream interface assignments
    assign m_axis_tdata = adc_result;
    assign m_axis_tvalid = data_valid;
    assign m_axis_tlast = 1'b1;  // Each sample is treated as end of packet

endmodule