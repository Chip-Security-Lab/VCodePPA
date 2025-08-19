//SystemVerilog
// SystemVerilog
// IEEE 1364-2005 Verilog Standard
// Restructured Asynchronous Shadow Register with improved PPA metrics
// Optimized data flow paths with pipelined architecture
//
module async_shadow_reg #(
    parameter WIDTH = 16
)(
    input  wire             clk,       // System clock
    input  wire             rst_n,     // Active low reset
    input  wire [WIDTH-1:0] data_in,   // Input data
    input  wire             shadow_en, // Shadow enable signal
    output reg  [WIDTH-1:0] shadow_out // Shadow output data - now registered
);
    // ===== DATA FLOW STAGE 1: INPUT CAPTURE =====
    reg [WIDTH-1:0] input_stage;     // Input capture register
    
    // Input stage capture - first pipeline stage
    always @(posedge clk or negedge rst_n) begin: input_capture_stage
        if (!rst_n)
            input_stage <= {WIDTH{1'b0}};
        else
            input_stage <= data_in;
    end
    
    // ===== DATA FLOW STAGE 2: MAIN STORAGE =====
    reg [WIDTH-1:0] main_reg;        // Main data register
    reg             shadow_en_r;     // Registered shadow enable
    
    // Main register update and enable registration
    always @(posedge clk or negedge rst_n) begin: main_storage_stage
        if (!rst_n) begin
            main_reg <= {WIDTH{1'b0}};
            shadow_en_r <= 1'b0;
        end
        else begin
            main_reg <= input_stage;
            shadow_en_r <= shadow_en;
        end
    end
    
    // ===== DATA FLOW STAGE 3: SHADOW STORAGE =====
    reg [WIDTH-1:0] shadow_reg;      // Shadow storage register
    
    // Shadow register update logic - stores main_reg value when enabled
    always @(posedge clk or negedge rst_n) begin: shadow_storage_stage
        if (!rst_n)
            shadow_reg <= {WIDTH{1'b0}};
        else if (shadow_en_r)
            shadow_reg <= main_reg;
    end
    
    // ===== DATA FLOW STAGE 4: OUTPUT SELECTION =====
    // Registered output mux to improve timing
    always @(posedge clk or negedge rst_n) begin: output_stage
        if (!rst_n)
            shadow_out <= {WIDTH{1'b0}};
        else
            shadow_out <= shadow_en_r ? main_reg : shadow_reg;
    end

endmodule