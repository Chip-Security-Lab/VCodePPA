module adaptive_crossbar (
    input wire clk, rst,
    input wire [31:0] data_in,
    input wire [1:0] mode,
    input wire [7:0] sel,
    input wire update_config,
    output reg [31:0] data_out
);
    // Configuration registers for different modes
    reg [1:0] config_sel[0:3][0:3]; // [mode][output]
    
    // Configuration update logic
    always @(posedge clk) begin
        if (rst) begin
            // Initialize configurations (default 1:1 mapping)
            config_sel[0][0] <= 2'd0; config_sel[1][0] <= 2'd0; 
            config_sel[2][0] <= 2'd0; config_sel[3][0] <= 2'd0;
            
            config_sel[0][1] <= 2'd1; config_sel[1][1] <= 2'd1; 
            config_sel[2][1] <= 2'd1; config_sel[3][1] <= 2'd1;
            
            config_sel[0][2] <= 2'd2; config_sel[1][2] <= 2'd2; 
            config_sel[2][2] <= 2'd2; config_sel[3][2] <= 2'd2;
            
            config_sel[0][3] <= 2'd3; config_sel[1][3] <= 2'd3; 
            config_sel[2][3] <= 2'd3; config_sel[3][3] <= 2'd3;
        end else if (update_config) begin
            // Update configuration for current mode
            config_sel[mode][0] <= sel[1:0];
            config_sel[mode][1] <= sel[3:2];
            config_sel[mode][2] <= sel[5:4];
            config_sel[mode][3] <= sel[7:6];
        end
    end
    
    // Crossbar switching
    wire [7:0] data_segments[0:3];
    assign data_segments[0] = data_in[7:0];
    assign data_segments[1] = data_in[15:8];
    assign data_segments[2] = data_in[23:16];
    assign data_segments[3] = data_in[31:24];
    
    always @(posedge clk) begin
        if (rst) begin
            data_out <= 32'h00000000;
        end else begin
            data_out[7:0] <= data_segments[config_sel[mode][0]];
            data_out[15:8] <= data_segments[config_sel[mode][1]];
            data_out[23:16] <= data_segments[config_sel[mode][2]];
            data_out[31:24] <= data_segments[config_sel[mode][3]];
        end
    end
endmodule