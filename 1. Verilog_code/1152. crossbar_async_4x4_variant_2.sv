//SystemVerilog
//=============================================================================
// Optimized Pipelined 4x4 Crossbar Switch with Improved Data Flow Architecture
//=============================================================================
module crossbar_async_4x4 (
    input  wire        clk,                  // System clock
    input  wire        rst_n,                // Active low reset
    input  wire [7:0]  data_in_0,            // Input port 0 data
    input  wire [7:0]  data_in_1,            // Input port 1 data
    input  wire [7:0]  data_in_2,            // Input port 2 data
    input  wire [7:0]  data_in_3,            // Input port 3 data
    input  wire [1:0]  select_out_0,         // Output port 0 selection
    input  wire [1:0]  select_out_1,         // Output port 1 selection
    input  wire [1:0]  select_out_2,         // Output port 2 selection
    input  wire [1:0]  select_out_3,         // Output port 3 selection
    output wire [7:0]  data_out_0,           // Output port 0 data
    output wire [7:0]  data_out_1,           // Output port 1 data
    output wire [7:0]  data_out_2,           // Output port 2 data
    output wire [7:0]  data_out_3            // Output port 3 data
);

    // Stage 1: Input data registration
    reg [7:0] data_in_reg_0;
    reg [7:0] data_in_reg_1;
    reg [7:0] data_in_reg_2;
    reg [7:0] data_in_reg_3;
    
    // Individual always blocks for each input data register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg_0 <= 8'h0;
        end else begin
            data_in_reg_0 <= data_in_0;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg_1 <= 8'h0;
        end else begin
            data_in_reg_1 <= data_in_1;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg_2 <= 8'h0;
        end else begin
            data_in_reg_2 <= data_in_2;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg_3 <= 8'h0;
        end else begin
            data_in_reg_3 <= data_in_3;
        end
    end
    
    // Stage 2: Selection registration - split into individual blocks
    reg [1:0] select_reg_0;
    reg [1:0] select_reg_1;
    reg [1:0] select_reg_2;
    reg [1:0] select_reg_3;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            select_reg_0 <= 2'b00;
        end else begin
            select_reg_0 <= select_out_0;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            select_reg_1 <= 2'b00;
        end else begin
            select_reg_1 <= select_out_1;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            select_reg_2 <= 2'b00;
        end else begin
            select_reg_2 <= select_out_2;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            select_reg_3 <= 2'b00;
        end else begin
            select_reg_3 <= select_out_3;
        end
    end
    
    // Stage 3: Data switching matrix
    // Using registered inputs for improved timing
    wire [7:0] input_array [0:3];
    assign input_array[0] = data_in_reg_0;
    assign input_array[1] = data_in_reg_1;
    assign input_array[2] = data_in_reg_2;
    assign input_array[3] = data_in_reg_3;
    
    // Stage 4: Intermediate switching results - split into individual blocks
    reg [7:0] data_switched_0;
    reg [7:0] data_switched_1;
    reg [7:0] data_switched_2;
    reg [7:0] data_switched_3;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_switched_0 <= 8'h0;
        end else begin
            data_switched_0 <= input_array[select_reg_0];
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_switched_1 <= 8'h0;
        end else begin
            data_switched_1 <= input_array[select_reg_1];
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_switched_2 <= 8'h0;
        end else begin
            data_switched_2 <= input_array[select_reg_2];
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_switched_3 <= 8'h0;
        end else begin
            data_switched_3 <= input_array[select_reg_3];
        end
    end
    
    // Final output assignment
    assign data_out_0 = data_switched_0;
    assign data_out_1 = data_switched_1;
    assign data_out_2 = data_switched_2;
    assign data_out_3 = data_switched_3;

endmodule