//SystemVerilog
//-----------------------------------------------------------------------------
// Top level module - Adaptive Crossbar with Valid-Ready handshake interface
//-----------------------------------------------------------------------------
module adaptive_crossbar (
    input wire clk, rst,
    // Data input interface with valid-ready handshake
    input wire [31:0] data_in,
    input wire data_in_valid,
    output wire data_in_ready,
    // Control signals
    input wire [1:0] mode,
    input wire [7:0] sel,
    input wire update_config,
    input wire update_config_valid,
    output wire update_config_ready,
    // Data output interface with valid-ready handshake
    output wire [31:0] data_out,
    output wire data_out_valid,
    input wire data_out_ready
);

    // Internal signals for connectivity between modules
    wire [1:0] config_sel_current [0:3];
    wire [7:0] data_segments [0:3];
    wire data_processing_ready;
    wire data_processing_valid;
    
    // Handshake logic
    assign data_in_ready = data_processing_ready;
    assign data_processing_valid = data_in_valid;
    assign update_config_ready = 1'b1; // Always ready to accept config updates
    
    // Data segmentation module instantiation
    data_segmenter u_data_segmenter (
        .data_in(data_in),
        .data_in_valid(data_in_valid),
        .data_segments(data_segments)
    );
    
    // Config storage and management module instantiation
    config_manager u_config_manager (
        .clk(clk),
        .rst(rst),
        .mode(mode),
        .sel(sel),
        .update_config(update_config),
        .update_config_valid(update_config_valid),
        .config_sel_current(config_sel_current)
    );
    
    // Crossbar switching module instantiation
    crossbar_switch u_crossbar_switch (
        .clk(clk),
        .rst(rst),
        .data_segments(data_segments),
        .data_in_valid(data_processing_valid),
        .data_in_ready(data_processing_ready),
        .config_sel(config_sel_current),
        .data_out(data_out),
        .data_out_valid(data_out_valid),
        .data_out_ready(data_out_ready)
    );

endmodule

//-----------------------------------------------------------------------------
// Data Segmenter Module - Breaks the input data into byte segments
//-----------------------------------------------------------------------------
module data_segmenter (
    input wire [31:0] data_in,
    input wire data_in_valid,
    output wire [7:0] data_segments [0:3]
);
    
    assign data_segments[0] = data_in[7:0];
    assign data_segments[1] = data_in[15:8];
    assign data_segments[2] = data_in[23:16];
    assign data_segments[3] = data_in[31:24];
    
endmodule

//-----------------------------------------------------------------------------
// Configuration Manager Module - Handles storage and updates of configs
//-----------------------------------------------------------------------------
module config_manager (
    input wire clk, rst,
    input wire [1:0] mode,
    input wire [7:0] sel,
    input wire update_config,
    input wire update_config_valid,
    output wire [1:0] config_sel_current [0:3]
);
    
    // Configuration registers for different modes
    reg [1:0] config_sel [0:3][0:3]; // [mode][output]
    
    // Output the current mode's configuration
    assign config_sel_current[0] = config_sel[mode][0];
    assign config_sel_current[1] = config_sel[mode][1];
    assign config_sel_current[2] = config_sel[mode][2];
    assign config_sel_current[3] = config_sel[mode][3];
    
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
        end else if (update_config && update_config_valid) begin
            // Update configuration for current mode when valid
            config_sel[mode][0] <= sel[1:0];
            config_sel[mode][1] <= sel[3:2];
            config_sel[mode][2] <= sel[5:4];
            config_sel[mode][3] <= sel[7:6];
        end
    end
    
endmodule

//-----------------------------------------------------------------------------
// Crossbar Switch Module - Performs the actual switching based on config
//-----------------------------------------------------------------------------
module crossbar_switch (
    input wire clk, rst,
    input wire [7:0] data_segments [0:3],
    input wire data_in_valid,
    output wire data_in_ready,
    input wire [1:0] config_sel [0:3],
    output reg [31:0] data_out,
    output reg data_out_valid,
    input wire data_out_ready
);
    
    // Internal state for handshaking
    reg processing_data;
    
    // Ready when not processing data or when output is accepted
    assign data_in_ready = !processing_data || (data_out_valid && data_out_ready);
    
    // Crossbar switching logic with handshaking
    always @(posedge clk) begin
        if (rst) begin
            data_out <= 32'h00000000;
            data_out_valid <= 1'b0;
            processing_data <= 1'b0;
        end else begin
            // When output is ready or not valid, we can process new data
            if (data_out_ready || !data_out_valid) begin
                if (data_in_valid && data_in_ready) begin
                    // Process new data when valid input and ready to accept
                    data_out[7:0]   <= data_segments[config_sel[0]];
                    data_out[15:8]  <= data_segments[config_sel[1]];
                    data_out[23:16] <= data_segments[config_sel[2]];
                    data_out[31:24] <= data_segments[config_sel[3]];
                    data_out_valid <= 1'b1;
                    processing_data <= 1'b0;
                end else if (data_out_valid && data_out_ready) begin
                    // Clear valid flag when data is consumed
                    data_out_valid <= 1'b0;
                end
            end else begin
                // Indicate processing when output not ready and valid
                processing_data <= 1'b1;
            end
        end
    end
    
endmodule