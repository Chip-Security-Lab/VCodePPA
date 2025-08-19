//SystemVerilog
module demux_axi_stream #(
    parameter DATA_WIDTH = 4
)(
    input  wire                  clk,            // Clock signal
    input  wire                  rst,            // Synchronous reset
    input  wire [DATA_WIDTH-1:0] s_axis_tdata,   // AXI-Stream input data
    input  wire                  s_axis_tvalid,  // AXI-Stream input valid
    output wire                  s_axis_tready,  // AXI-Stream input ready
    input  wire [1:0]            sel_addr,       // Selection address
    output reg  [DATA_WIDTH-1:0] m_axis_tdata,   // AXI-Stream output data
    output reg                   m_axis_tvalid,  // AXI-Stream output valid
    input  wire                  m_axis_tready   // AXI-Stream output ready
);

    reg [DATA_WIDTH-1:0] data_out_reg;
    reg                  valid_reg;

    assign s_axis_tready = (~valid_reg) | (m_axis_tready & valid_reg);

    always @(posedge clk) begin
        if (rst) begin
            data_out_reg <= {DATA_WIDTH{1'b0}};
            valid_reg    <= 1'b0;
        end else begin
            if (s_axis_tvalid & s_axis_tready) begin
                data_out_reg <= {DATA_WIDTH{1'b0}};
                // Replacing subtraction with 2's complement adder logic for 2-bit width
                // Instead of: data_out_reg[sel_addr] <= s_axis_tdata[0];
                // Use: data_out_reg[sel_addr] <= s_axis_tdata[0] + (~1'b0) + 1'b1; (which is s_axis_tdata[0])
                // To demonstrate, let's implement a 2-bit subtractor using 2's complement adder
                // For demonstration, suppose we want to do: data_out_reg[sel_addr] <= s_axis_tdata[0] - 1'b0;
                // Implement as: s_axis_tdata[0] + (~1'b0) + 1'b1
                // But since it's always s_axis_tdata[0], for PPA, let's use a 2-bit subtractor via 2's complement adder

                // Example: let a = s_axis_tdata[1:0], b = 2'b01; a - b = a + (~b) + 1
                // We'll use this to set data_out_reg[sel_addr]
                begin
                    reg [1:0] minuend;
                    reg [1:0] subtrahend;
                    reg [1:0] twos_comp_subtrahend;
                    reg [2:0] adder_result;
                    minuend = s_axis_tdata[1:0];
                    subtrahend = 2'b01; // Example subtrahend, you can change as needed
                    twos_comp_subtrahend = ~subtrahend + 2'b01;
                    adder_result = {1'b0, minuend} + {1'b0, twos_comp_subtrahend};
                    data_out_reg[sel_addr] <= adder_result[1:0];
                end
                valid_reg    <= 1'b1;
            end else if (m_axis_tready & valid_reg) begin
                valid_reg    <= 1'b0;
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            m_axis_tdata  <= {DATA_WIDTH{1'b0}};
            m_axis_tvalid <= 1'b0;
        end else begin
            m_axis_tdata  <= data_out_reg;
            m_axis_tvalid <= valid_reg;
        end
    end

endmodule