//SystemVerilog
// Top-level Demultiplexer Module with Asynchronous Reset (Retimed)
module demux_async_reset (
    input  wire        clk,              // Clock signal
    input  wire        rst_n,            // Active-low async reset
    input  wire        data,             // Input data
    input  wire [2:0]  channel,          // Channel selection
    output wire [7:0]  out_channels      // Output channels
);

    // Internal register for input data and channel (retimed register moved forward)
    reg        data_reg;
    reg [2:0]  channel_reg;

    // Internal wire for demux logic output
    wire [7:0] demux_out_vec;

    // Demultiplexer Logic (now directly feeds output)
    demux_async_reset_logic u_demux_logic (
        .data    (data_reg),
        .channel (channel_reg),
        .out_vec (demux_out_vec)
    );

    // Output assignment: direct combinational output from demux logic
    assign out_channels = demux_out_vec;

    // Input register with Asynchronous Reset (retimed from output to input side)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg    <= 1'b0;
            channel_reg <= 3'b000;
        end else begin
            data_reg    <= data;
            channel_reg <= channel;
        end
    end

endmodule

// -----------------------------------------------------------------------------
// Submodule: Demultiplexer Logic
// Function: Decodes channel and data into one-hot output vector
// -----------------------------------------------------------------------------
module demux_async_reset_logic (
    input  wire        data,           // Input data
    input  wire [2:0]  channel,        // Channel selection
    output reg  [7:0]  out_vec         // One-hot demux output
);
    integer i;
    always @(*) begin
        out_vec = 8'b0;
        if (data) begin
            out_vec[channel] = 1'b1;
        end
    end
endmodule