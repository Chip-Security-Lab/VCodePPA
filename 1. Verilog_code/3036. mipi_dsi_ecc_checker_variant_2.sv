//SystemVerilog
module mipi_dsi_ecc_checker_axi (
  input wire aclk,
  input wire aresetn,
  
  // AXI-Stream Slave Interface
  input wire [31:0] s_axis_tdata,
  input wire s_axis_tvalid,
  output reg s_axis_tready,
  input wire s_axis_tlast,
  
  // AXI-Stream Master Interface
  output reg [31:0] m_axis_tdata,
  output reg m_axis_tvalid,
  input wire m_axis_tready,
  output reg m_axis_tlast,
  
  // Error indicator
  output reg ecc_error
);

  // Internal signals
  wire [23:0] header_data;
  wire [7:0] ecc_in;
  wire [7:0] parity_bits;
  reg [7:0] ecc_calculated;
  reg header_valid;
  
  // Extract header data and ECC from AXI-Stream data
  assign header_data = s_axis_tdata[23:0];
  assign ecc_in = s_axis_tdata[31:24];
  
  // Pre-calculate XOR terms for each parity bit
  assign parity_bits[0] = header_data[0] ^ header_data[2] ^ header_data[4] ^ header_data[6] ^
                         header_data[8] ^ header_data[10] ^ header_data[12] ^ header_data[14] ^
                         header_data[16] ^ header_data[18] ^ header_data[20] ^ header_data[22];
  
  assign parity_bits[1] = header_data[1] ^ header_data[2] ^ header_data[5] ^ header_data[6] ^
                         header_data[9] ^ header_data[10] ^ header_data[13] ^ header_data[14] ^
                         header_data[17] ^ header_data[18] ^ header_data[21] ^ header_data[22];
  
  assign parity_bits[2] = header_data[3] ^ header_data[4] ^ header_data[5] ^ header_data[6] ^
                         header_data[11] ^ header_data[12] ^ header_data[13] ^ header_data[14] ^
                         header_data[19] ^ header_data[20] ^ header_data[21] ^ header_data[22];
  
  assign parity_bits[3] = header_data[7] ^ header_data[8] ^ header_data[9] ^ header_data[10] ^
                         header_data[11] ^ header_data[12] ^ header_data[13] ^ header_data[14] ^
                         header_data[23];
  
  assign parity_bits[4] = header_data[15] ^ header_data[16] ^ header_data[17] ^ header_data[18] ^
                         header_data[19] ^ header_data[20] ^ header_data[21] ^ header_data[22] ^
                         header_data[23];
  
  assign parity_bits[5] = header_data[0] ^ header_data[1] ^ header_data[2] ^ header_data[3] ^
                         header_data[4] ^ header_data[5] ^ header_data[6] ^ header_data[7] ^
                         header_data[8] ^ header_data[9] ^ header_data[10] ^ header_data[11] ^
                         header_data[12] ^ header_data[13] ^ header_data[14] ^ header_data[15];
  
  assign parity_bits[6] = header_data[16] ^ header_data[17] ^ header_data[18] ^ header_data[19] ^
                         header_data[20] ^ header_data[21] ^ header_data[22] ^ header_data[23];
  
  assign parity_bits[7] = ~(header_data[0] ^ header_data[1] ^ header_data[2] ^ header_data[3] ^
                           header_data[4] ^ header_data[5] ^ header_data[6] ^ header_data[7] ^
                           header_data[8] ^ header_data[9] ^ header_data[10] ^ header_data[11] ^
                           header_data[12] ^ header_data[13] ^ header_data[14] ^ header_data[15] ^
                           header_data[16] ^ header_data[17] ^ header_data[18] ^ header_data[19] ^
                           header_data[20] ^ header_data[21] ^ header_data[22] ^ header_data[23]);

  // AXI-Stream handshake logic
  reg [1:0] state;
  localparam IDLE = 2'b00;
  localparam PROCESS = 2'b01;
  localparam OUTPUT = 2'b10;
  
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      state <= IDLE;
      s_axis_tready <= 1'b0;
      m_axis_tvalid <= 1'b0;
      m_axis_tdata <= 32'h0;
      m_axis_tlast <= 1'b0;
      ecc_error <= 1'b0;
      ecc_calculated <= 8'h00;
      header_valid <= 1'b0;
    end else begin
      case (state)
        IDLE: begin
          s_axis_tready <= 1'b1;
          m_axis_tvalid <= 1'b0;
          if (s_axis_tvalid) begin
            state <= PROCESS;
            header_valid <= 1'b1;
          end
        end
        
        PROCESS: begin
          s_axis_tready <= 1'b0;
          header_valid <= 1'b0;
          ecc_calculated <= parity_bits;
          ecc_error <= (parity_bits != ecc_in);
          state <= OUTPUT;
        end
        
        OUTPUT: begin
          m_axis_tvalid <= 1'b1;
          m_axis_tdata <= {ecc_calculated, header_data};
          m_axis_tlast <= 1'b1;
          
          if (m_axis_tready) begin
            state <= IDLE;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
          end
        end
        
        default: state <= IDLE;
      endcase
    end
  end

endmodule