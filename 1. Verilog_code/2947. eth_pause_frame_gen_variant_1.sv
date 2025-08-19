//SystemVerilog
module eth_pause_frame_gen (
    input wire clk,
    input wire reset,
    input wire generate_pause,
    input wire [15:0] pause_time,
    input wire [47:0] local_mac,
    output reg [7:0] tx_data,
    output reg tx_en,
    output reg frame_complete
);
    // Multicast MAC address for PAUSE frames
    localparam [47:0] PAUSE_ADDR = 48'h010000C28001;
    localparam [15:0] MAC_CONTROL = 16'h8808;
    localparam [15:0] PAUSE_OPCODE = 16'h0001;
    
    // Pipeline stage definitions
    localparam IDLE = 5'd0, PREAMBLE = 5'd1, SFD = 5'd2;
    localparam DST_ADDR = 5'd3, SRC_ADDR = 5'd4, LENGTH = 5'd5;
    localparam OPCODE = 5'd6, PAUSE_PARAM = 5'd7, PAD = 5'd8, FCS = 5'd9;
    
    // Pipeline stage 1 - State control
    reg [4:0] state_stage1;
    reg [3:0] counter_stage1;
    reg tx_en_stage1;
    reg frame_complete_stage1;
    reg generate_pause_r;
    
    // Pipeline stage 2 - Data preparation
    reg [4:0] state_stage2;
    reg [3:0] counter_stage2;
    reg tx_en_stage2;
    reg frame_complete_stage2;
    reg [7:0] tx_data_stage2;
    
    // Pipeline control signals
    reg pipeline_valid_stage1;
    reg pipeline_valid_stage2;
    
    // Input register
    reg [15:0] pause_time_r;
    reg [47:0] local_mac_r;
    
    // Pipeline stage 1: Control and state logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_stage1 <= IDLE;
            counter_stage1 <= 4'd0;
            tx_en_stage1 <= 1'b0;
            frame_complete_stage1 <= 1'b0;
            pipeline_valid_stage1 <= 1'b0;
            generate_pause_r <= 1'b0;
            pause_time_r <= 16'd0;
            local_mac_r <= 48'd0;
        end else begin
            // Register inputs
            generate_pause_r <= generate_pause;
            pause_time_r <= pause_time;
            local_mac_r <= local_mac;
            
            // Default values
            pipeline_valid_stage1 <= 1'b0;
            
            if (state_stage1 == IDLE && generate_pause_r) begin
                state_stage1 <= PREAMBLE;
                counter_stage1 <= 4'd0;
                tx_en_stage1 <= 1'b1;
                frame_complete_stage1 <= 1'b0;
                pipeline_valid_stage1 <= 1'b1;
            end else if (state_stage1 == IDLE) begin
                tx_en_stage1 <= 1'b0;
                pipeline_valid_stage1 <= 1'b0;
            end else if (state_stage1 == PREAMBLE && counter_stage1 == 4'd6) begin
                state_stage1 <= SFD;
                counter_stage1 <= 4'd0;
                pipeline_valid_stage1 <= 1'b1;
            end else if (state_stage1 == PREAMBLE) begin
                counter_stage1 <= counter_stage1 + 1'b1;
                pipeline_valid_stage1 <= 1'b1;
            end else if (state_stage1 == SFD) begin
                state_stage1 <= DST_ADDR;
                counter_stage1 <= 4'd0;
                pipeline_valid_stage1 <= 1'b1;
            end else if (state_stage1 == DST_ADDR && counter_stage1 == 4'd5) begin
                state_stage1 <= SRC_ADDR;
                counter_stage1 <= 4'd0;
                pipeline_valid_stage1 <= 1'b1;
            end else if (state_stage1 == DST_ADDR) begin
                counter_stage1 <= counter_stage1 + 1'b1;
                pipeline_valid_stage1 <= 1'b1;
            end else if (state_stage1 == SRC_ADDR && counter_stage1 == 4'd5) begin
                state_stage1 <= LENGTH;
                counter_stage1 <= 4'd0;
                pipeline_valid_stage1 <= 1'b1;
            end else if (state_stage1 == SRC_ADDR) begin
                counter_stage1 <= counter_stage1 + 1'b1;
                pipeline_valid_stage1 <= 1'b1;
            end else if (state_stage1 == LENGTH && counter_stage1 == 4'd0) begin
                counter_stage1 <= counter_stage1 + 1'b1;
                pipeline_valid_stage1 <= 1'b1;
            end else if (state_stage1 == LENGTH) begin
                state_stage1 <= OPCODE;
                counter_stage1 <= 4'd0;
                pipeline_valid_stage1 <= 1'b1;
            end else if (state_stage1 == OPCODE && counter_stage1 == 4'd0) begin
                counter_stage1 <= counter_stage1 + 1'b1;
                pipeline_valid_stage1 <= 1'b1;
            end else if (state_stage1 == OPCODE) begin
                state_stage1 <= PAUSE_PARAM;
                counter_stage1 <= 4'd0;
                pipeline_valid_stage1 <= 1'b1;
            end else if (state_stage1 == PAUSE_PARAM && counter_stage1 == 4'd0) begin
                counter_stage1 <= counter_stage1 + 1'b1;
                pipeline_valid_stage1 <= 1'b1;
            end else if (state_stage1 == PAUSE_PARAM) begin
                state_stage1 <= PAD;
                counter_stage1 <= 4'd0;
                pipeline_valid_stage1 <= 1'b1;
            end else if (state_stage1 == PAD && counter_stage1 == 4'd9) begin
                state_stage1 <= FCS;
                counter_stage1 <= 4'd0;
                pipeline_valid_stage1 <= 1'b1;
            end else if (state_stage1 == PAD) begin
                counter_stage1 <= counter_stage1 + 1'b1;
                pipeline_valid_stage1 <= 1'b1;
            end else if (state_stage1 == FCS && counter_stage1 == 4'd3) begin
                state_stage1 <= IDLE;
                frame_complete_stage1 <= 1'b1;
                tx_en_stage1 <= 1'b0;
                pipeline_valid_stage1 <= 1'b0;
            end else if (state_stage1 == FCS) begin
                counter_stage1 <= counter_stage1 + 1'b1;
                pipeline_valid_stage1 <= 1'b1;
            end
        end
    end
    
    // Pipeline stage 2: Data generation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_stage2 <= IDLE;
            counter_stage2 <= 4'd0;
            tx_en_stage2 <= 1'b0;
            tx_data_stage2 <= 8'd0;
            frame_complete_stage2 <= 1'b0;
            pipeline_valid_stage2 <= 1'b0;
        end else begin
            // Pass control signals to next stage
            state_stage2 <= state_stage1;
            counter_stage2 <= counter_stage1;
            tx_en_stage2 <= tx_en_stage1;
            frame_complete_stage2 <= frame_complete_stage1;
            pipeline_valid_stage2 <= pipeline_valid_stage1;
            
            // Data generation logic
            if (pipeline_valid_stage1) begin
                if (state_stage1 == PREAMBLE) begin
                    tx_data_stage2 <= 8'h55;
                end else if (state_stage1 == SFD) begin
                    tx_data_stage2 <= 8'hD5;
                end else if (state_stage1 == DST_ADDR && counter_stage1 == 4'd0) begin
                    tx_data_stage2 <= PAUSE_ADDR[47:40];
                end else if (state_stage1 == DST_ADDR && counter_stage1 == 4'd1) begin
                    tx_data_stage2 <= PAUSE_ADDR[39:32];
                end else if (state_stage1 == DST_ADDR && counter_stage1 == 4'd2) begin
                    tx_data_stage2 <= PAUSE_ADDR[31:24];
                end else if (state_stage1 == DST_ADDR && counter_stage1 == 4'd3) begin
                    tx_data_stage2 <= PAUSE_ADDR[23:16];
                end else if (state_stage1 == DST_ADDR && counter_stage1 == 4'd4) begin
                    tx_data_stage2 <= PAUSE_ADDR[15:8];
                end else if (state_stage1 == DST_ADDR) begin
                    tx_data_stage2 <= PAUSE_ADDR[7:0];
                end else if (state_stage1 == SRC_ADDR && counter_stage1 == 4'd0) begin
                    tx_data_stage2 <= local_mac_r[47:40];
                end else if (state_stage1 == SRC_ADDR && counter_stage1 == 4'd1) begin
                    tx_data_stage2 <= local_mac_r[39:32];
                end else if (state_stage1 == SRC_ADDR && counter_stage1 == 4'd2) begin
                    tx_data_stage2 <= local_mac_r[31:24];
                end else if (state_stage1 == SRC_ADDR && counter_stage1 == 4'd3) begin
                    tx_data_stage2 <= local_mac_r[23:16];
                end else if (state_stage1 == SRC_ADDR && counter_stage1 == 4'd4) begin
                    tx_data_stage2 <= local_mac_r[15:8];
                end else if (state_stage1 == SRC_ADDR) begin
                    tx_data_stage2 <= local_mac_r[7:0];
                end else if (state_stage1 == LENGTH && counter_stage1 == 4'd0) begin
                    tx_data_stage2 <= MAC_CONTROL[15:8];
                end else if (state_stage1 == LENGTH) begin
                    tx_data_stage2 <= MAC_CONTROL[7:0];
                end else if (state_stage1 == OPCODE && counter_stage1 == 4'd0) begin
                    tx_data_stage2 <= PAUSE_OPCODE[15:8];
                end else if (state_stage1 == OPCODE) begin
                    tx_data_stage2 <= PAUSE_OPCODE[7:0];
                end else if (state_stage1 == PAUSE_PARAM && counter_stage1 == 4'd0) begin
                    tx_data_stage2 <= pause_time_r[15:8];
                end else if (state_stage1 == PAUSE_PARAM) begin
                    tx_data_stage2 <= pause_time_r[7:0];
                end else if (state_stage1 == PAD) begin
                    tx_data_stage2 <= 8'h00;
                end else if (state_stage1 == FCS) begin
                    // Simplified FCS - in a real design this would be calculated
                    tx_data_stage2 <= 8'hAA;
                end else begin
                    tx_data_stage2 <= 8'd0;
                end
            end
        end
    end
    
    // Output assignment stage
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tx_data <= 8'd0;
            tx_en <= 1'b0;
            frame_complete <= 1'b0;
        end else begin
            // Register stage 2 outputs to module outputs
            tx_data <= tx_data_stage2;
            tx_en <= tx_en_stage2;
            frame_complete <= frame_complete_stage2;
        end
    end
endmodule