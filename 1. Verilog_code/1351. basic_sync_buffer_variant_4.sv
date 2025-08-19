//SystemVerilog
// Top level module
module basic_sync_buffer (
    input wire clk,
    input wire rst,  // Added reset for pipeline control
    input wire [7:0] data_in,
    input wire write_en,
    input wire data_valid_in,  // Data valid input signal
    output wire [7:0] data_out,
    output wire data_valid_out  // Data valid output signal
);
    // Pipeline stage signals
    wire write_en_stage1, write_en_stage2;
    wire data_valid_stage1, data_valid_stage2, data_valid_stage3;
    wire [7:0] data_stage1, data_stage2, data_stage3;
    
    // Submodule instantiations
    write_control_unit wcu (
        .clk(clk),
        .rst(rst),
        .write_en(write_en),
        .data_valid_in(data_valid_in),
        .qualified_write_en(write_en_stage1),
        .data_valid_out(data_valid_stage1)
    );
    
    data_path_unit dpu (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .write_en(write_en_stage1),
        .data_valid_in(data_valid_stage1),
        .data_out(data_stage2),
        .write_en_out(write_en_stage2),
        .data_valid_out(data_valid_stage2)
    );
    
    output_buffer obuf (
        .clk(clk),
        .rst(rst),
        .data_in(data_stage2),
        .data_valid_in(data_valid_stage2),
        .data_out(data_out),
        .data_valid_out(data_valid_out)
    );
    
endmodule

// Write control unit - Stage 1 of pipeline
module write_control_unit (
    input wire clk,
    input wire rst,
    input wire write_en,
    input wire data_valid_in,
    output reg qualified_write_en,
    output reg data_valid_out
);
    reg write_en_meta;
    
    always @(posedge clk) begin
        if (rst) begin
            write_en_meta <= 1'b0;
            qualified_write_en <= 1'b0;
            data_valid_out <= 1'b0;
        end else begin
            // Stage 1 pipeline registers
            write_en_meta <= write_en;
            qualified_write_en <= write_en_meta;
            data_valid_out <= data_valid_in;
        end
    end
endmodule

// Data path unit - Stage 2 of pipeline
module data_path_unit (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire write_en,
    input wire data_valid_in,
    output reg [7:0] data_out,
    output reg write_en_out,
    output reg data_valid_out
);
    // Stage 2 intermediate registers
    reg [7:0] data_stage1;
    
    always @(posedge clk) begin
        if (rst) begin
            data_stage1 <= 8'h00;
            data_out <= 8'h00;
            write_en_out <= 1'b0;
            data_valid_out <= 1'b0;
        end else begin
            // Process data in pipeline stages
            if (write_en)
                data_stage1 <= data_in;
                
            // Register data for next stage
            data_out <= data_stage1;
            
            // Forward control signals
            write_en_out <= write_en;
            data_valid_out <= data_valid_in;
        end
    end
endmodule

// Output buffer - Stage 3 of pipeline
module output_buffer (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire data_valid_in,
    output reg [7:0] data_out,
    output reg data_valid_out
);
    always @(posedge clk) begin
        if (rst) begin
            data_out <= 8'h00;
            data_valid_out <= 1'b0;
        end else begin
            // Final pipeline stage
            data_out <= data_in;
            data_valid_out <= data_valid_in;
        end
    end
endmodule