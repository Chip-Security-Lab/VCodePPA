//SystemVerilog
module adaptive_crossbar (
    input wire clk, rst,
    input wire [31:0] data_in,
    input wire [1:0] mode,
    input wire [7:0] sel,
    input wire update_config,
    output reg [31:0] data_out
);
    // Configuration registers - optimized as a 3D packed array
    reg [1:0] config_sel [0:3][0:3]; // [mode][output]
    
    // Input data segments as packed arrays for easier indexing
    wire [7:0] data_segments [0:3];
    assign {data_segments[3], data_segments[2], data_segments[1], data_segments[0]} = data_in;
    
    // Buffered signals for high fanout reduction
    reg [1:0] mode_buf1, mode_buf2;
    reg [7:0] sel_buf1, sel_buf2;
    reg update_config_buf;
    reg [7:0] data_segments_buf [0:3][0:1]; // Two-level buffering for data_segments
    
    // Buffer registers for high fanout signals
    always @(posedge clk) begin
        // Mode signal buffering
        mode_buf1 <= mode;
        mode_buf2 <= mode_buf1;
        
        // Sel signal buffering
        sel_buf1 <= sel;
        sel_buf2 <= sel_buf1;
        
        // Update config buffering
        update_config_buf <= update_config;
        
        // Data segments buffering - first level
        for (integer i = 0; i < 4; i = i + 1) begin
            data_segments_buf[i][0] <= data_segments[i];
        end
        
        // Data segments buffering - second level
        for (integer i = 0; i < 4; i = i + 1) begin
            data_segments_buf[i][1] <= data_segments_buf[i][0];
        end
    end
    
    // Configuration update logic with simplified initialization
    always @(posedge clk) begin
        if (rst) begin
            // Initialize configurations using for loops for better readability and synthesis
            for (integer i = 0; i < 4; i = i + 1) begin
                for (integer j = 0; j < 4; j = j + 1) begin
                    config_sel[i][j] <= j[1:0]; // Default 1:1 mapping
                end
            end
        end 
        else if (update_config_buf) begin
            // Optimized parallel update using bit slicing with buffered sel
            config_sel[mode_buf1][0] <= sel_buf2[1:0];
            config_sel[mode_buf1][1] <= sel_buf2[3:2];
            config_sel[mode_buf1][2] <= sel_buf2[5:4];
            config_sel[mode_buf1][3] <= sel_buf2[7:6];
        end
    end
    
    // Crossbar switching - optimized to reduce mux stages
    reg [1:0] current_sel [0:3];
    reg [1:0] current_sel_buf [0:3];
    
    // Loop variable registers to reduce fanout
    reg [1:0] i_buf1, i_buf2;
    
    always @(posedge clk) begin
        // Buffer the loop index for better fanout control
        i_buf1 <= i_buf1 + 1'b1;
        if (i_buf1 == 2'b11) begin
            i_buf1 <= 2'b00;
        end
        i_buf2 <= i_buf1;
        
        if (rst) begin
            data_out <= 32'h00000000;
            for (integer i = 0; i < 4; i = i + 1) begin
                current_sel[i] <= 2'b00;
                current_sel_buf[i] <= 2'b00;
            end
        end 
        else begin
            // Pre-select config values based on mode to reduce combinational path
            current_sel[i_buf2] <= config_sel[mode_buf2][i_buf2];
            
            // Buffer the current selection to reduce fanout
            current_sel_buf[i_buf2] <= current_sel[i_buf2];
            
            // Map outputs using current selection with buffered signals
            // Pipeline the output assignment to improve timing
            case (i_buf2)
                2'b00: data_out[7:0]   <= data_segments_buf[current_sel_buf[0]][1];
                2'b01: data_out[15:8]  <= data_segments_buf[current_sel_buf[1]][1];
                2'b10: data_out[23:16] <= data_segments_buf[current_sel_buf[2]][1];
                2'b11: data_out[31:24] <= data_segments_buf[current_sel_buf[3]][1];
            endcase
        end
    end
endmodule