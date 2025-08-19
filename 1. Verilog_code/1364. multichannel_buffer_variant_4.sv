//SystemVerilog
// SystemVerilog - IEEE 1364-2005 Standard
module multichannel_buffer (
    input wire clk,
    input wire [3:0] channel_select,
    input wire [7:0] data_in,
    input wire write_en,
    output wire [7:0] data_out
);
    // Internal signals for module interconnection
    wire [3:0] channel_select_stage1;
    wire [3:0] channel_select_stage2;
    wire [7:0] data_in_stage1;
    wire write_en_stage1;
    wire [7:0] read_data_stage2;

    // Input pipeline stage
    input_stage u_input_stage (
        .clk(clk),
        .channel_select_in(channel_select),
        .data_in(data_in),
        .write_en_in(write_en),
        .channel_select_out(channel_select_stage1),
        .data_out(data_in_stage1),
        .write_en_out(write_en_stage1)
    );

    // Memory access stage
    memory_stage u_memory_stage (
        .clk(clk),
        .channel_select_in(channel_select_stage1),
        .data_in(data_in_stage1),
        .write_en(write_en_stage1),
        .channel_select_out(channel_select_stage2),
        .read_data_out(read_data_stage2)
    );

    // Output registration stage
    output_stage u_output_stage (
        .clk(clk),
        .read_data_in(read_data_stage2),
        .data_out(data_out)
    );
endmodule

module input_stage (
    input wire clk,
    input wire [3:0] channel_select_in,
    input wire [7:0] data_in,
    input wire write_en_in,
    output reg [3:0] channel_select_out,
    output reg [7:0] data_out,
    output reg write_en_out
);
    // Register channel selection
    always @(posedge clk) begin
        channel_select_out <= channel_select_in;
    end
    
    // Register data input
    always @(posedge clk) begin
        data_out <= data_in;
    end
    
    // Register write enable signal
    always @(posedge clk) begin
        write_en_out <= write_en_in;
    end
endmodule

module memory_stage (
    input wire clk,
    input wire [3:0] channel_select_in,
    input wire [7:0] data_in,
    input wire write_en,
    output reg [3:0] channel_select_out,
    output reg [7:0] read_data_out
);
    // Memory storage for 16 channels
    reg [7:0] channels [0:15];
    
    // Write operation logic (pipelined)
    always @(posedge clk) begin
        if (write_en)
            channels[channel_select_in] <= data_in;
    end
    
    // Read address forwarding logic
    always @(posedge clk) begin
        channel_select_out <= channel_select_in;
    end
    
    // Read operation logic (pipelined)
    always @(posedge clk) begin
        read_data_out <= channels[channel_select_in];
    end
endmodule

module output_stage (
    input wire clk,
    input wire [7:0] read_data_in,
    output reg [7:0] data_out
);
    // Output registration
    always @(posedge clk) begin
        data_out <= read_data_in;
    end
endmodule