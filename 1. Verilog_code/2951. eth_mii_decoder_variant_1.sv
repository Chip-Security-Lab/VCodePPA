//SystemVerilog - IEEE 1364-2005
module eth_mii_decoder_axi (
    // Clock and Reset
    input wire s_axi_aclk,
    input wire s_axi_aresetn,
    
    // AXI4-Lite Slave Interface - Write Address Channel
    input wire [31:0] s_axi_awaddr,
    input wire s_axi_awvalid,
    output reg s_axi_awready,
    
    // AXI4-Lite Slave Interface - Write Data Channel
    input wire [31:0] s_axi_wdata,
    input wire [3:0] s_axi_wstrb,
    input wire s_axi_wvalid,
    output reg s_axi_wready,
    
    // AXI4-Lite Slave Interface - Write Response Channel
    output reg [1:0] s_axi_bresp,
    output reg s_axi_bvalid,
    input wire s_axi_bready,
    
    // AXI4-Lite Slave Interface - Read Address Channel
    input wire [31:0] s_axi_araddr,
    input wire s_axi_arvalid,
    output reg s_axi_arready,
    
    // AXI4-Lite Slave Interface - Read Data Channel
    output reg [31:0] s_axi_rdata,
    output reg [1:0] s_axi_rresp,
    output reg s_axi_rvalid,
    input wire s_axi_rready,
    
    // Original MII Interface
    input wire rx_clk,
    input wire rx_dv,
    input wire rx_er,
    input wire [3:0] rxd
);

    // AXI4-Lite response codes
    localparam RESP_OKAY = 2'b00;
    localparam RESP_ERROR = 2'b10;
    
    // Register addresses
    localparam ADDR_DATA_OUT = 4'h0;      // 0x00
    localparam ADDR_STATUS = 4'h1;        // 0x04
    
    // Ethernet decoder states
    localparam IDLE = 3'b000, PREAMBLE_S1 = 3'b001, PREAMBLE_S2 = 3'b010, 
               SFD_S1 = 3'b011, SFD_S2 = 3'b100, DATA_S1 = 3'b101, DATA_S2 = 3'b110;
    
    // Original eth_mii_decoder signals with additional pipeline stages
    reg [7:0] data_out_stage1;
    reg [7:0] data_out_stage2;
    reg [7:0] data_out;
    
    reg data_valid_stage1;
    reg data_valid_stage2;
    reg data_valid;
    
    reg error_stage1;
    reg error_stage2;
    reg error;
    
    reg sfd_detected_stage1;
    reg sfd_detected_stage2;
    reg sfd_detected;
    
    reg carrier_sense_stage1;
    reg carrier_sense_stage2;
    reg carrier_sense;
    
    reg [2:0] state;
    reg [3:0] prev_rxd_stage1;
    reg [3:0] prev_rxd_stage2;
    reg [3:0] rxd_stage1;
    reg rx_dv_stage1;
    reg rx_er_stage1;
    
    // Status register bits
    // [0] = data_valid
    // [1] = error
    // [2] = sfd_detected
    // [3] = carrier_sense
    reg [3:0] status_reg;
    
    // AXI4-Lite control registers
    reg [3:0] read_addr;
    reg read_req;
    reg write_req;
    reg [3:0] write_addr;
    reg [31:0] write_data;
    
    // CDC signals - add more pipeline stages for clock domain crossing
    reg [7:0] data_out_sync_stage1;
    reg [7:0] data_out_sync_stage2;
    reg [7:0] data_out_sync;
    
    reg [3:0] status_sync_stage1;
    reg [3:0] status_sync_stage2;
    reg [3:0] status_sync;
    
    // AXI Write control signals
    reg write_addr_valid;
    reg [3:0] write_addr_stage1;
    reg write_data_valid;
    reg [31:0] write_data_stage1;
    reg write_resp_pending;
    
    // AXI Read control signals
    reg read_addr_valid;
    reg [3:0] read_addr_stage1;
    reg [31:0] read_data_stage1;
    reg [1:0] read_resp_stage1;
    reg read_data_valid;
    
    // RX clock domain processes
    always @(posedge rx_clk) begin
        if (!s_axi_aresetn) begin
            // Reset input pipeline stage
            rxd_stage1 <= 4'h0;
            rx_dv_stage1 <= 1'b0;
            rx_er_stage1 <= 1'b0;
            
            // Reset decoder state and pipeline stages
            state <= IDLE;
            data_out_stage1 <= 8'h00;
            data_out_stage2 <= 8'h00;
            data_out <= 8'h00;
            
            data_valid_stage1 <= 1'b0;
            data_valid_stage2 <= 1'b0;
            data_valid <= 1'b0;
            
            error_stage1 <= 1'b0;
            error_stage2 <= 1'b0;
            error <= 1'b0;
            
            sfd_detected_stage1 <= 1'b0;
            sfd_detected_stage2 <= 1'b0;
            sfd_detected <= 1'b0;
            
            carrier_sense_stage1 <= 1'b0;
            carrier_sense_stage2 <= 1'b0;
            carrier_sense <= 1'b0;
            
            prev_rxd_stage1 <= 4'h0;
            prev_rxd_stage2 <= 4'h0;
        end else begin
            // Input pipeline stage
            rxd_stage1 <= rxd;
            rx_dv_stage1 <= rx_dv;
            rx_er_stage1 <= rx_er;
            
            // Stage 3 (final output registers)
            data_out <= data_out_stage2;
            data_valid <= data_valid_stage2;
            error <= error_stage2;
            sfd_detected <= sfd_detected_stage2;
            carrier_sense <= carrier_sense_stage2;
            
            // Stage 2
            data_out_stage2 <= data_out_stage1;
            data_valid_stage2 <= data_valid_stage1;
            error_stage2 <= error_stage1;
            sfd_detected_stage2 <= sfd_detected_stage1;
            carrier_sense_stage2 <= carrier_sense_stage1;
            prev_rxd_stage2 <= prev_rxd_stage1;
            
            // Stage 1 (core logic)
            prev_rxd_stage1 <= rxd_stage1;
            error_stage1 <= rx_er_stage1;
            carrier_sense_stage1 <= rx_dv_stage1;
            data_valid_stage1 <= 1'b0;
            sfd_detected_stage1 <= 1'b0;
            
            if (rx_dv_stage1) begin
                case (state)
                    IDLE: begin
                        if (rxd_stage1 == 4'h5)
                            state <= PREAMBLE_S1;
                    end
                    
                    PREAMBLE_S1: begin
                        if (rxd_stage1 == 4'h5)
                            state <= PREAMBLE_S2;
                        else if (rxd_stage1 == 4'hD)
                            state <= SFD_S1;
                        else
                            state <= IDLE;
                    end
                    
                    PREAMBLE_S2: begin
                        if (rxd_stage1 == 4'h5)
                            state <= PREAMBLE_S2;
                        else if (rxd_stage1 == 4'hD)
                            state <= SFD_S1;
                        else
                            state <= IDLE;
                    end
                    
                    SFD_S1: begin
                        if (rxd_stage1 == 4'h5 && prev_rxd_stage1 == 4'hD) begin
                            state <= SFD_S2;
                        end else
                            state <= IDLE;
                    end
                    
                    SFD_S2: begin
                        sfd_detected_stage1 <= 1'b1;
                        state <= DATA_S1;
                        data_out_stage1[3:0] <= rxd_stage1;
                    end
                    
                    DATA_S1: begin
                        state <= DATA_S2;
                        data_out_stage1[3:0] <= rxd_stage1;
                    end
                    
                    DATA_S2: begin
                        data_out_stage1[7:4] <= rxd_stage1;
                        data_out_stage1[3:0] <= prev_rxd_stage1;
                        data_valid_stage1 <= 1'b1;
                        state <= DATA_S1;
                    end
                    
                    default: state <= IDLE;
                endcase
            end else begin
                state <= IDLE;
            end
        end
    end

    // AXI clock domain processes
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            // Reset CDC signals
            data_out_sync_stage1 <= 8'h00;
            data_out_sync_stage2 <= 8'h00;
            data_out_sync <= 8'h00;
            
            status_sync_stage1 <= 4'h0;
            status_sync_stage2 <= 4'h0;
            status_sync <= 4'h0;
            
            // Reset AXI4-Lite Write Channel signals
            s_axi_awready <= 1'b0;
            write_addr_valid <= 1'b0;
            write_addr_stage1 <= 4'h0;
            s_axi_wready <= 1'b0;
            write_data_valid <= 1'b0;
            write_data_stage1 <= 32'h0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= RESP_OKAY;
            write_resp_pending <= 1'b0;
            write_req <= 1'b0;
            write_addr <= 4'h0;
            write_data <= 32'h0;
            
            // Reset AXI4-Lite Read Channel signals
            s_axi_arready <= 1'b0;
            read_addr_valid <= 1'b0;
            read_addr_stage1 <= 4'h0;
            read_req <= 1'b0;
            read_addr <= 4'h0;
            read_data_stage1 <= 32'h0;
            read_resp_stage1 <= RESP_OKAY;
            read_data_valid <= 1'b0;
            s_axi_rvalid <= 1'b0;
            s_axi_rdata <= 32'h0;
            s_axi_rresp <= RESP_OKAY;
        end else begin
            // Clock domain crossing logic
            data_out_sync_stage1 <= data_out;
            status_sync_stage1[0] <= data_valid;
            status_sync_stage1[1] <= error;
            status_sync_stage1[2] <= sfd_detected;
            status_sync_stage1[3] <= carrier_sense;
            
            data_out_sync_stage2 <= data_out_sync_stage1;
            status_sync_stage2 <= status_sync_stage1;
            
            data_out_sync <= data_out_sync_stage2;
            status_sync <= status_sync_stage2;
            
            // AXI4-Lite Write Address Channel
            if (s_axi_awvalid && !s_axi_awready && !write_addr_valid) begin
                s_axi_awready <= 1'b1;
                write_addr_stage1 <= s_axi_awaddr[5:2];
                write_addr_valid <= 1'b1;
            end else begin
                s_axi_awready <= 1'b0;
                if (write_addr_valid && !write_req) begin
                    write_addr <= write_addr_stage1;
                    write_req <= 1'b1;
                    write_addr_valid <= 1'b0;
                end else if (s_axi_wvalid && s_axi_wready) begin
                    write_req <= 1'b0;
                end
            end
            
            // AXI4-Lite Write Data Channel
            if (s_axi_wvalid && !s_axi_wready && write_req && !write_data_valid) begin
                s_axi_wready <= 1'b1;
                write_data_stage1 <= s_axi_wdata;
                write_data_valid <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
                if (write_data_valid) begin
                    write_data <= write_data_stage1;
                    write_data_valid <= 1'b0;
                end
            end
            
            // AXI4-Lite Write Response Channel
            if (s_axi_wvalid && s_axi_wready && !write_resp_pending) begin
                write_resp_pending <= 1'b1;
            end else if (write_resp_pending && !s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp <= RESP_OKAY;
                write_resp_pending <= 1'b0;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
            
            // AXI4-Lite Read Address Channel
            if (s_axi_arvalid && !s_axi_arready && !read_addr_valid && !read_req) begin
                s_axi_arready <= 1'b1;
                read_addr_stage1 <= s_axi_araddr[5:2];
                read_addr_valid <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
                if (read_addr_valid) begin
                    read_addr <= read_addr_stage1;
                    read_req <= 1'b1;
                    read_addr_valid <= 1'b0;
                end else if (read_req && s_axi_rvalid && s_axi_rready) begin
                    read_req <= 1'b0;
                end
            end
            
            // AXI4-Lite Read Data Channel
            if (read_req && !read_data_valid && !s_axi_rvalid) begin
                read_data_valid <= 1'b1;
                read_resp_stage1 <= RESP_OKAY;
                
                case (read_addr)
                    ADDR_DATA_OUT: read_data_stage1 <= {24'h0, data_out_sync};
                    ADDR_STATUS: read_data_stage1 <= {28'h0, status_sync};
                    default: begin
                        read_data_stage1 <= 32'h0;
                        read_resp_stage1 <= RESP_ERROR;
                    end
                endcase
            end else if (read_data_valid && !s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rdata <= read_data_stage1;
                s_axi_rresp <= read_resp_stage1;
                read_data_valid <= 1'b0;
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end
    
endmodule