//SystemVerilog
//IEEE 1364-2005 Verilog

module can_frame_assembler(
  input wire clk, rst_n,
  input wire [10:0] id,
  input wire [7:0] data [0:7],
  input wire [3:0] dlc,
  input wire rtr, ide, assemble,
  output wire [127:0] frame,
  output wire frame_ready
);
  
  // Internal signals for controller to datapath communication
  wire start_assembly;
  wire assembly_done;
  
  // Output signals from frame_formatter
  wire [127:0] formatted_frame;
  
  // Instantiate controller module
  can_controller controller_inst (
    .clk(clk),
    .rst_n(rst_n),
    .assemble(assemble),
    .assembly_done(assembly_done),
    .start_assembly(start_assembly),
    .frame_ready(frame_ready)
  );
  
  // Instantiate frame formatter module
  can_frame_formatter formatter_inst (
    .clk(clk),
    .rst_n(rst_n),
    .id(id),
    .data(data),
    .dlc(dlc),
    .rtr(rtr),
    .ide(ide),
    .start_assembly(start_assembly),
    .formatted_frame(formatted_frame),
    .assembly_done(assembly_done)
  );
  
  // Connect formatter output to top-level output
  assign frame = formatted_frame;
  
endmodule

// Controller module - handles state machine logic
module can_controller(
  input wire clk, rst_n,
  input wire assemble,
  input wire assembly_done,
  output reg start_assembly,
  output reg frame_ready
);
  localparam IDLE = 1'b0;
  localparam ASSEMBLING = 1'b1;
  
  reg state, next_state;
  
  // State register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      state <= IDLE;
    else
      state <= next_state;
  end
  
  // Next state logic
  always @(*) begin
    case (state)
      IDLE: begin
        if (assemble)
          next_state = ASSEMBLING;
        else
          next_state = IDLE;
      end
      
      ASSEMBLING: begin
        if (!assemble)
          next_state = IDLE;
        else
          next_state = ASSEMBLING;
      end
      
      default: next_state = IDLE;
    endcase
  end
  
  // Output logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      start_assembly <= 1'b0;
      frame_ready <= 1'b0;
    end
    else begin
      case (state)
        IDLE: begin
          if (assemble) begin
            start_assembly <= 1'b1;
            frame_ready <= 1'b0;
          end
          else begin
            start_assembly <= 1'b0;
            frame_ready <= 1'b0;
          end
        end
        
        ASSEMBLING: begin
          start_assembly <= 1'b0;
          if (assembly_done)
            frame_ready <= 1'b1;
          else if (!assemble)
            frame_ready <= 1'b0;
        end
        
        default: begin
          start_assembly <= 1'b0;
          frame_ready <= 1'b0;
        end
      endcase
    end
  end
endmodule

// Frame formatter module - handles data formatting and assembly
module can_frame_formatter(
  input wire clk, rst_n,
  input wire [10:0] id,
  input wire [7:0] data [0:7],
  input wire [3:0] dlc,
  input wire rtr, ide,
  input wire start_assembly,
  output reg [127:0] formatted_frame,
  output reg assembly_done
);
  
  // CRC calculator instance
  wire [14:0] crc_result;
  wire crc_valid;
  
  can_crc_calculator crc_inst (
    .clk(clk),
    .rst_n(rst_n),
    .id(id),
    .data(data),
    .dlc(dlc),
    .rtr(rtr),
    .ide(ide),
    .start_calc(start_assembly),
    .crc_result(crc_result),
    .crc_valid(crc_valid)
  );
  
  // Frame assembly process
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      formatted_frame <= 128'h0;
      assembly_done <= 1'b0;
    end
    else begin
      if (start_assembly) begin
        // SOF (1 bit)
        formatted_frame[0] <= 1'b0;
        
        // Identifier (11 bits)
        formatted_frame[11:1] <= id;
        
        // RTR, IDE, r0 bits
        formatted_frame[12] <= rtr;
        formatted_frame[13] <= ide;
        formatted_frame[14] <= 1'b0; // r0 reserved bit
        
        // DLC (4 bits)
        formatted_frame[18:15] <= dlc;
        
        // Data (0-8 bytes)
        if (!rtr) begin
          formatted_frame[82:19] <= {data[0], data[1], data[2], data[3], 
                                   data[4], data[5], data[6], data[7]};
        end
        else begin
          formatted_frame[82:19] <= 64'h0;
        end
        
        // Add CRC field when available
        if (crc_valid) begin
          formatted_frame[97:83] <= crc_result;
          assembly_done <= 1'b1;
        end
        else begin
          assembly_done <= 1'b0;
        end
      end
      else if (crc_valid) begin
        formatted_frame[97:83] <= crc_result;
        assembly_done <= 1'b1;
      end
    end
  end
endmodule

// CRC calculator module
module can_crc_calculator(
  input wire clk, rst_n,
  input wire [10:0] id,
  input wire [7:0] data [0:7],
  input wire [3:0] dlc,
  input wire rtr, ide,
  input wire start_calc,
  output reg [14:0] crc_result,
  output reg crc_valid
);
  // Local parameters for CRC calculation
  localparam CRC15_POLY = 15'h4599; // CAN standard polynomial
  
  reg [7:0] bytes_to_process;
  reg [7:0] byte_counter;
  reg [14:0] crc_reg;
  reg calculating;
  
  // Process to count bytes to include in CRC
  always @(*) begin
    if (rtr)
      bytes_to_process = 4'd2; // Only ID and control fields
    else
      bytes_to_process = 4'd2 + dlc; // ID, control, and data fields
  end
  
  // CRC calculation state machine
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      crc_reg <= 15'h0;
      byte_counter <= 8'h0;
      crc_valid <= 1'b0;
      calculating <= 1'b0;
      crc_result <= 15'h0;
    end
    else begin
      if (start_calc) begin
        crc_reg <= 15'h0; // Initial value
        byte_counter <= 8'h0;
        crc_valid <= 1'b0;
        calculating <= 1'b1;
      end
      else if (calculating) begin
        if (byte_counter < bytes_to_process) begin
          // Select byte to process based on counter
          reg [7:0] current_byte;
          case (byte_counter)
            8'd0: current_byte = {5'b0, id[10:8]}; // Upper 3 bits of ID
            8'd1: current_byte = id[7:0]; // Lower 8 bits of ID
            8'd2: current_byte = {rtr, ide, 2'b0, dlc}; // Control bits
            default: begin
              if (byte_counter - 8'd3 < 8)
                current_byte = data[byte_counter - 8'd3];
              else
                current_byte = 8'h0;
            end
          endcase
          
          // Process byte bit by bit for CRC
          for (integer i = 0; i < 8; i = i + 1) begin
            reg msb;
            msb = crc_reg[14] ^ current_byte[i];
            crc_reg = {crc_reg[13:0], 1'b0};
            if (msb)
              crc_reg = crc_reg ^ CRC15_POLY;
          end
          
          byte_counter <= byte_counter + 8'd1;
        end
        else begin
          crc_result <= crc_reg;
          crc_valid <= 1'b1;
          calculating <= 1'b0;
        end
      end
      else if (!start_calc) begin
        crc_valid <= 1'b0;
      end
    end
  end
endmodule