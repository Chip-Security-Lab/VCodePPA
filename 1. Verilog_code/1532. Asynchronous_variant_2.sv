//SystemVerilog
// IEEE 1364-2005 Verilog Standard
module async_shadow_reg #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire shadow_en,
    output wire [WIDTH-1:0] shadow_out
);
    // Internal connection signals
    wire [WIDTH-1:0] data_capture_out;
    wire [WIDTH-1:0] main_data_out;
    wire [WIDTH-1:0] shadow_storage_out;
    
    // Instantiate data capture pipeline stage
    data_capture_stage #(
        .WIDTH(WIDTH)
    ) u_data_capture (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_capture_out)
    );
    
    // Instantiate main data processing stage
    main_data_stage #(
        .WIDTH(WIDTH)
    ) u_main_data (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_capture_out),
        .data_out(main_data_out)
    );
    
    // Instantiate shadow storage stage
    shadow_storage_stage #(
        .WIDTH(WIDTH)
    ) u_shadow_storage (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(main_data_out),
        .shadow_en(shadow_en),
        .data_out(shadow_storage_out)
    );
    
    // Instantiate output selection logic
    output_selector #(
        .WIDTH(WIDTH)
    ) u_output_selector (
        .clk(clk),
        .rst_n(rst_n),
        .main_data(main_data_out),
        .shadow_data(shadow_storage_out),
        .shadow_en(shadow_en),
        .shadow_out(shadow_out)
    );
    
endmodule

// Stage 1: Data capture module
module data_capture_stage #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    // Register input data with reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= {WIDTH{1'b0}};
        else
            data_out <= data_in;
    end
endmodule

// Stage 2: Main data processing module
module main_data_stage #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    // Process and register data with reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= {WIDTH{1'b0}};
        else
            data_out <= data_in;
    end
endmodule

// Stage 3: Shadow storage module
module shadow_storage_stage #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire shadow_en,
    output reg [WIDTH-1:0] data_out
);
    // Store shadow value when enabled
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= {WIDTH{1'b0}};
        else if (shadow_en)
            data_out <= data_in;
    end
endmodule

// Output selection logic module
module output_selector #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] main_data,
    input wire [WIDTH-1:0] shadow_data,
    input wire shadow_en,
    output reg [WIDTH-1:0] shadow_out
);
    // Select and register output with improved timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_out <= {WIDTH{1'b0}};
        else if (shadow_en)
            shadow_out <= main_data;
        else
            shadow_out <= shadow_data;
    end
endmodule