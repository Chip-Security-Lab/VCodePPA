//SystemVerilog
module rz_codec (
    input wire clk,
    input wire rst_n,
    
    // AXI4-Lite Slave Interface
    // Write Address Channel
    input wire [7:0] s_axi_awaddr,
    input wire s_axi_awvalid,
    output reg s_axi_awready,
    
    // Write Data Channel
    input wire [31:0] s_axi_wdata,
    input wire [3:0] s_axi_wstrb,
    input wire s_axi_wvalid,
    output reg s_axi_wready,
    
    // Write Response Channel
    output reg [1:0] s_axi_bresp,
    output reg s_axi_bvalid,
    input wire s_axi_bready,
    
    // Read Address Channel
    input wire [7:0] s_axi_araddr,
    input wire s_axi_arvalid,
    output reg s_axi_arready,
    
    // Read Data Channel
    output reg [31:0] s_axi_rdata,
    output reg [1:0] s_axi_rresp,
    output reg s_axi_rvalid,
    input wire s_axi_rready,
    
    // Original output signals
    output reg rz_out,        // Encoded output
    output reg data_out,      // Decoded output
    output reg valid_out      // Valid decoded bit
);
    
    // Parameter and register definitions
    localparam ADDR_DATA_IN   = 8'h00;
    localparam ADDR_RZ_IN     = 8'h04;
    localparam ADDR_STATUS    = 8'h08;
    
    // Internal signals and registers
    reg data_in;
    reg data_in_stage1;
    reg data_in_stage2;
    reg rz_in;
    reg rz_in_stage1;
    reg rz_in_stage2;
    reg [1:0] bit_phase;
    reg [1:0] bit_phase_stage1;
    reg [1:0] bit_phase_stage2;
    reg [1:0] sample_count;
    reg data_sampled;
    reg data_sampled_stage1;
    
    // Pipeline control signals
    reg valid_stage1;
    reg valid_stage2;
    reg valid_stage3;
    
    // AXI write states - now with more pipeline stages
    localparam WRITE_IDLE = 3'b000;
    localparam WRITE_ADDR_RECV = 3'b001;
    localparam WRITE_ADDR_PROC = 3'b010;
    localparam WRITE_DATA_RECV = 3'b011;
    localparam WRITE_DATA_PROC = 3'b100;
    localparam WRITE_RESP_PREP = 3'b101;
    localparam WRITE_RESP_SEND = 3'b110;
    reg [2:0] write_state;
    
    // AXI read states - now with more pipeline stages
    localparam READ_IDLE = 3'b000;
    localparam READ_ADDR_RECV = 3'b001;
    localparam READ_ADDR_PROC = 3'b010;
    localparam READ_DATA_PREP = 3'b011;
    localparam READ_DATA_SEND = 3'b100;
    reg [2:0] read_state;
    
    // Latched address values
    reg [7:0] awaddr_latch;
    reg [7:0] awaddr_proc;
    reg [7:0] araddr_latch;
    reg [7:0] araddr_proc;
    
    // Data processing registers
    reg [31:0] wdata_latch;
    reg [3:0] wstrb_latch;
    reg [31:0] rdata_prep;
    
    // AXI4-Lite Write Channel - Deeper pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_state <= WRITE_IDLE;
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00;
            awaddr_latch <= 8'h00;
            awaddr_proc <= 8'h00;
            wdata_latch <= 32'h0;
            wstrb_latch <= 4'h0;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    if (s_axi_awvalid) begin
                        awaddr_latch <= s_axi_awaddr;
                        s_axi_awready <= 1'b1;
                        write_state <= WRITE_ADDR_RECV;
                    end
                end
                
                WRITE_ADDR_RECV: begin
                    s_axi_awready <= 1'b0;
                    awaddr_proc <= awaddr_latch;  // Pipeline stage for address processing
                    write_state <= WRITE_ADDR_PROC;
                end
                
                WRITE_ADDR_PROC: begin
                    if (s_axi_wvalid) begin
                        s_axi_wready <= 1'b1;
                        write_state <= WRITE_DATA_RECV;
                    end
                end
                
                WRITE_DATA_RECV: begin
                    s_axi_wready <= 1'b0;
                    wdata_latch <= s_axi_wdata;   // Pipeline stage for data capture
                    wstrb_latch <= s_axi_wstrb;
                    write_state <= WRITE_DATA_PROC;
                end
                
                WRITE_DATA_PROC: begin
                    // Handle register writes based on address
                    if (wstrb_latch[0]) begin
                        case (awaddr_proc)
                            ADDR_DATA_IN: data_in <= wdata_latch[0];
                            ADDR_RZ_IN: rz_in <= wdata_latch[0];
                            default: ; // No operation for unknown addresses
                        endcase
                    end
                    write_state <= WRITE_RESP_PREP;
                end
                
                WRITE_RESP_PREP: begin
                    s_axi_bresp <= 2'b00; // OKAY response
                    s_axi_bvalid <= 1'b1;
                    write_state <= WRITE_RESP_SEND;
                end
                
                WRITE_RESP_SEND: begin
                    if (s_axi_bready) begin
                        s_axi_bvalid <= 1'b0;
                        write_state <= WRITE_IDLE;
                    end
                end
                
                default: write_state <= WRITE_IDLE;
            endcase
        end
    end
    
    // AXI4-Lite Read Channel - Deeper pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_state <= READ_IDLE;
            s_axi_arready <= 1'b0;
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= 2'b00;
            s_axi_rdata <= 32'h0;
            araddr_latch <= 8'h00;
            araddr_proc <= 8'h00;
            rdata_prep <= 32'h0;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    if (s_axi_arvalid) begin
                        araddr_latch <= s_axi_araddr;
                        s_axi_arready <= 1'b1;
                        read_state <= READ_ADDR_RECV;
                    end
                end
                
                READ_ADDR_RECV: begin
                    s_axi_arready <= 1'b0;
                    araddr_proc <= araddr_latch;  // Pipeline stage for address processing
                    read_state <= READ_ADDR_PROC;
                end
                
                READ_ADDR_PROC: begin
                    // Prepare read data based on address
                    case (araddr_proc)
                        ADDR_DATA_IN: rdata_prep <= {31'b0, data_in};
                        ADDR_RZ_IN: rdata_prep <= {31'b0, rz_in};
                        ADDR_STATUS: rdata_prep <= {29'b0, valid_out, data_out, rz_out};
                        default: rdata_prep <= 32'h0;
                    endcase
                    read_state <= READ_DATA_PREP;
                end
                
                READ_DATA_PREP: begin
                    s_axi_rdata <= rdata_prep;    // Pipeline stage for data preparation
                    s_axi_rresp <= 2'b00;         // OKAY response
                    s_axi_rvalid <= 1'b1;
                    read_state <= READ_DATA_SEND;
                end
                
                READ_DATA_SEND: begin
                    if (s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                        read_state <= READ_IDLE;
                    end
                end
                
                default: read_state <= READ_IDLE;
            endcase
        end
    end
    
    // Bit phase counter with pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_phase <= 2'b00;
            bit_phase_stage1 <= 2'b00;
            bit_phase_stage2 <= 2'b00;
        end else begin
            bit_phase <= bit_phase + 1'b1;
            bit_phase_stage1 <= bit_phase;        // Pipeline stage 1
            bit_phase_stage2 <= bit_phase_stage1; // Pipeline stage 2
        end
    end
    
    // Input data pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1 <= 1'b0;
            data_in_stage2 <= 1'b0;
            rz_in_stage1 <= 1'b0;
            rz_in_stage2 <= 1'b0;
        end else begin
            data_in_stage1 <= data_in;        // Pipeline stage 1
            data_in_stage2 <= data_in_stage1; // Pipeline stage 2
            rz_in_stage1 <= rz_in;            // Pipeline stage 1
            rz_in_stage2 <= rz_in_stage1;     // Pipeline stage 2
        end
    end
    
    // RZ encoder - now with pipeline stages
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rz_out <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            // Stage 1: Determine encoder output based on bit phase
            case (bit_phase)
                2'b00: begin
                    valid_stage1 <= 1'b1;
                    rz_out <= data_in;   // First half of bit is high for '1'
                end
                2'b10: begin
                    valid_stage1 <= 1'b1;
                    rz_out <= 1'b0;      // Second half always returns to zero
                end
                default: valid_stage1 <= 1'b0;
            endcase
        end
    end
    
    // RZ decoder - now with a deeper pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_count <= 2'b00;
            data_sampled <= 1'b0;
            data_sampled_stage1 <= 1'b0;
            data_out <= 1'b0;
            valid_out <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            // Stage 1: Sample data based on bit phase
            case (bit_phase)
                2'b00: begin
                    data_sampled <= rz_in; // Sample first half of bit
                    valid_stage2 <= 1'b0;
                end
                2'b10: begin
                    valid_stage2 <= 1'b1;
                end
                default: valid_stage2 <= 1'b0;
            endcase
            
            // Stage 2: Pass sampled data to next stage
            data_sampled_stage1 <= data_sampled;
            valid_stage3 <= valid_stage2;
            
            // Stage 3: Process samples to detect RZ pattern
            if (valid_stage3) begin
                if (bit_phase_stage2 == 2'b10) begin
                    // Detect valid RZ pattern (high followed by low)
                    if (data_sampled_stage1 == 1'b1 && rz_in_stage2 == 1'b0)
                        data_out <= 1'b1;
                    else if (data_sampled_stage1 == 1'b0 && rz_in_stage2 == 1'b0)
                        data_out <= 1'b0;
                    valid_out <= 1'b1;
                end else begin
                    valid_out <= 1'b0;
                end
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule