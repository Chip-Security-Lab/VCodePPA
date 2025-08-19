//SystemVerilog
`timescale 1ns / 1ps
module distributed_priority_intr_ctrl(
  input clk, rst,
  input [15:0] intr_data,    // Interrupt data
  input        intr_valid,   // Sender asserts valid when data is available
  output       intr_ready,   // Receiver asserts ready when it can accept data
  output reg [3:0] id,       // Interrupt ID
  output reg valid           // Output valid signal
);
  wire [1:0] group_id;
  wire [3:0] group_req;
  wire [3:0] sub_id;
  wire valid_next;
  
  // Handshake control signals
  reg data_received;
  reg [15:0] req;
  
  // Handshaking logic
  assign intr_ready = !valid || data_received;  // Ready to accept new data when not processing or current data processed
  
  // Capture interrupt data when valid and ready
  always @(posedge clk) begin
    if (rst) begin
      req <= 16'b0;
      data_received <= 1'b0;
    end else if (intr_valid && intr_ready) begin
      req <= intr_data;
      data_received <= 1'b1;
    end else if (data_received && !valid_next) begin
      // Data has been processed completely
      data_received <= 1'b0;
    end
  end
  
  // Group-level priority detection - more efficient bit grouping
  assign group_req = {|req[15:12], |req[11:8], |req[7:4], |req[3:0]};
  
  // Optimized group priority encoder using casex
  reg [1:0] grp_encoder_out;
  always @(*) begin
    casex(group_req)
      4'b???1: grp_encoder_out = 2'd0; // LSB has highest priority
      4'b??10: grp_encoder_out = 2'd1;
      4'b?100: grp_encoder_out = 2'd2;
      4'b1000: grp_encoder_out = 2'd3;
      default: grp_encoder_out = 2'd0;
    endcase
  end
  assign group_id = grp_encoder_out;
  
  // Optimized sub-priority encoder using mux structure
  reg [3:0] sub_encoder_out;
  always @(*) begin
    case(group_id)
      2'd0: begin
        casex(req[3:0])
          4'b???1: sub_encoder_out = 4'd0;
          4'b??10: sub_encoder_out = 4'd1;
          4'b?100: sub_encoder_out = 4'd2;
          4'b1000: sub_encoder_out = 4'd3;
          default: sub_encoder_out = 4'd0;
        endcase
      end
      
      2'd1: begin
        casex(req[7:4])
          4'b???1: sub_encoder_out = 4'd4;
          4'b??10: sub_encoder_out = 4'd5;
          4'b?100: sub_encoder_out = 4'd6;
          4'b1000: sub_encoder_out = 4'd7;
          default: sub_encoder_out = 4'd4;
        endcase
      end
      
      2'd2: begin
        casex(req[11:8])
          4'b???1: sub_encoder_out = 4'd8;
          4'b??10: sub_encoder_out = 4'd9;
          4'b?100: sub_encoder_out = 4'd10;
          4'b1000: sub_encoder_out = 4'd11;
          default: sub_encoder_out = 4'd8;
        endcase
      end
      
      2'd3: begin
        casex(req[15:12])
          4'b???1: sub_encoder_out = 4'd12;
          4'b??10: sub_encoder_out = 4'd13;
          4'b?100: sub_encoder_out = 4'd14;
          4'b1000: sub_encoder_out = 4'd15;
          default: sub_encoder_out = 4'd12;
        endcase
      end
    endcase
  end
  assign sub_id = sub_encoder_out;
  
  // Valid signal logic
  assign valid_next = data_received && |req;
  
  // Sequential logic
  always @(posedge clk) begin
    if (rst) begin
      id <= 4'd0;
      valid <= 1'b0;
    end else begin
      valid <= valid_next;
      id <= sub_id;
    end
  end
endmodule