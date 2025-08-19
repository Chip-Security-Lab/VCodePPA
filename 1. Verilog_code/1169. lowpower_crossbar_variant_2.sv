//SystemVerilog
module lowpower_crossbar_axi (
    // Global signals
    input wire aclk,
    input wire aresetn,
    
    // AXI4-Lite Slave interface - Write Address Channel
    input wire [31:0] s_axil_awaddr,
    input wire [2:0] s_axil_awprot,
    input wire s_axil_awvalid,
    output reg s_axil_awready,
    
    // AXI4-Lite Slave interface - Write Data Channel
    input wire [63:0] s_axil_wdata,
    input wire [7:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output reg s_axil_wready,
    
    // AXI4-Lite Slave interface - Write Response Channel
    output reg [1:0] s_axil_bresp,
    output reg s_axil_bvalid,
    input wire s_axil_bready,
    
    // AXI4-Lite Slave interface - Read Address Channel
    input wire [31:0] s_axil_araddr,
    input wire [2:0] s_axil_arprot,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // AXI4-Lite Slave interface - Read Data Channel
    output reg [63:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready,
    
    // Output data (same as original)
    output reg [63:0] out_data
);

    // Internal registers to store the configuration
    reg [63:0] reg_in_data_stage1;
    reg [63:0] reg_in_data_stage2;
    reg [7:0] reg_out_sel_stage1;
    reg [7:0] reg_out_sel_stage2;
    reg [3:0] reg_in_valid_stage1;
    reg [3:0] reg_in_valid_stage2;
    
    // Clock gating signals
    wire [3:0] clk_en_stage1;
    reg [3:0] clk_en_stage2;
    
    // Enable clock only for outputs that have valid data
    genvar g;
    generate
        for (g = 0; g < 4; g = g + 1) begin : gen_clk_en
            assign clk_en_stage1[g] = |reg_in_valid_stage1;
        end
    endgenerate
    
    // Create output generation for each segment
    wire [15:0] output_segment_stage1[0:3];
    reg [15:0] output_segment_stage2[0:3];
    reg [15:0] output_segment_stage3[0:3];
    
    // Segment calculation pipeline - Stage 1
    genvar j;
    generate
        for (g = 0; g < 4; g = g + 1) begin : gen_output
            // Default values
            reg [15:0] segment_value;
            
            always @(*) begin
                segment_value = 16'h0000;
                if (reg_in_valid_stage1[0] && reg_out_sel_stage1[1:0] == g) segment_value = reg_in_data_stage1[15:0];
                if (reg_in_valid_stage1[1] && reg_out_sel_stage1[3:2] == g) segment_value = reg_in_data_stage1[31:16];
                if (reg_in_valid_stage1[2] && reg_out_sel_stage1[5:4] == g) segment_value = reg_in_data_stage1[47:32];
                if (reg_in_valid_stage1[3] && reg_out_sel_stage1[7:6] == g) segment_value = reg_in_data_stage1[63:48];
            end
            
            assign output_segment_stage1[g] = segment_value;
        end
    endgenerate
    
    // FSM states for AXI4-Lite interface - Added more states for pipelining
    localparam IDLE = 3'b000;
    localparam WRITE_ADDR = 3'b001;
    localparam WRITE_DATA = 3'b010;
    localparam WRITE_RESP = 3'b011;
    localparam READ_ADDR = 3'b100;
    localparam READ_PROC = 3'b101;
    localparam READ_DATA = 3'b110;
    
    reg [2:0] current_state, next_state;
    reg [31:0] read_addr_stage1, read_addr_stage2;
    reg [31:0] write_addr_stage1, write_addr_stage2;
    reg [63:0] write_data_stage1;
    
    // Stage 2 and 3 pipeline registers for output generation
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            // Reset pipeline registers for data path
            reg_in_data_stage2 <= 64'h0;
            reg_out_sel_stage2 <= 8'h0;
            reg_in_valid_stage2 <= 4'h0;
            clk_en_stage2 <= 4'h0;
            
            // Reset output segment registers
            for (int i = 0; i < 4; i = i + 1) begin
                output_segment_stage2[i] <= 16'h0000;
                output_segment_stage3[i] <= 16'h0000;
            end
        end else begin
            // Pipeline stage 1 to stage 2
            reg_in_data_stage2 <= reg_in_data_stage1;
            reg_out_sel_stage2 <= reg_out_sel_stage1;
            reg_in_valid_stage2 <= reg_in_valid_stage1;
            clk_en_stage2 <= clk_en_stage1;
            
            // Pipeline stage 1 to stage 2 for output segments
            for (int i = 0; i < 4; i = i + 1) begin
                output_segment_stage2[i] <= output_segment_stage1[i];
            end
            
            // Pipeline stage 2 to stage 3 for output segments
            for (int i = 0; i < 4; i = i + 1) begin
                output_segment_stage3[i] <= output_segment_stage2[i];
            end
        end
    end
    
    // State machine for AXI transactions
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            current_state <= IDLE;
            read_addr_stage1 <= 32'h0;
            read_addr_stage2 <= 32'h0;
            write_addr_stage1 <= 32'h0;
            write_addr_stage2 <= 32'h0;
            write_data_stage1 <= 64'h0;
        end else begin
            current_state <= next_state;
            
            // Pipeline stage for address registers
            read_addr_stage2 <= read_addr_stage1;
            write_addr_stage2 <= write_addr_stage1;
            
            // Capture addresses in appropriate states
            if (current_state == IDLE && s_axil_awvalid) begin
                write_addr_stage1 <= s_axil_awaddr;
            end
            
            if (current_state == IDLE && s_axil_arvalid) begin
                read_addr_stage1 <= s_axil_araddr;
            end
            
            // Capture write data
            if (current_state == WRITE_ADDR && s_axil_wvalid) begin
                write_data_stage1 <= s_axil_wdata;
            end
        end
    end
    
    // Next state logic - Enhanced state machine for pipelining
    always @(*) begin
        next_state = current_state;
        
        case (current_state)
            IDLE: begin
                if (s_axil_awvalid) begin
                    next_state = WRITE_ADDR;
                end else if (s_axil_arvalid) begin
                    next_state = READ_ADDR;
                end
            end
            
            WRITE_ADDR: begin
                if (s_axil_wvalid) begin
                    next_state = WRITE_DATA;
                end
            end
            
            WRITE_DATA: begin
                next_state = WRITE_RESP;
            end
            
            WRITE_RESP: begin
                if (s_axil_bready) begin
                    next_state = IDLE;
                end
            end
            
            READ_ADDR: begin
                next_state = READ_PROC;
            end
            
            READ_PROC: begin
                next_state = READ_DATA;
            end
            
            READ_DATA: begin
                if (s_axil_rready) begin
                    next_state = IDLE;
                end
            end
        endcase
    end
    
    // Control signals and data logic - Modified for pipelined architecture
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rresp <= 2'b00;
            s_axil_rdata <= 64'h0;
            
            // Reset configuration registers
            reg_in_data_stage1 <= 64'h0;
            reg_out_sel_stage1 <= 8'h0;
            reg_in_valid_stage1 <= 4'h0;
            
            out_data <= 64'h0000_0000_0000_0000;
        end else begin
            // Default values
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_arready <= 1'b0;
            
            case (current_state)
                IDLE: begin
                    s_axil_bvalid <= 1'b0;
                    s_axil_rvalid <= 1'b0;
                    
                    if (s_axil_awvalid) begin
                        s_axil_awready <= 1'b1;
                    end else if (s_axil_arvalid) begin
                        s_axil_arready <= 1'b1;
                    end
                end
                
                WRITE_ADDR: begin
                    if (s_axil_wvalid) begin
                        s_axil_wready <= 1'b1;
                    end
                end
                
                WRITE_DATA: begin
                    // Process write data based on address
                    case (write_addr_stage2[7:0])
                        8'h00: reg_in_data_stage1 <= write_data_stage1;
                        8'h08: reg_out_sel_stage1 <= write_data_stage1[7:0];
                        8'h0C: reg_in_valid_stage1 <= write_data_stage1[3:0];
                        default: begin end
                    endcase
                end
                
                WRITE_RESP: begin
                    s_axil_bvalid <= 1'b1;
                    s_axil_bresp <= 2'b00; // OKAY response
                    
                    if (s_axil_bready) begin
                        s_axil_bvalid <= 1'b0;
                    end
                end
                
                READ_ADDR: begin
                    // First stage of read operation
                end
                
                READ_PROC: begin
                    // Second stage of read operation - prepare data
                    case (read_addr_stage2[7:0])
                        8'h00: s_axil_rdata <= reg_in_data_stage2;
                        8'h08: s_axil_rdata <= {56'h0, reg_out_sel_stage2};
                        8'h0C: s_axil_rdata <= {60'h0, reg_in_valid_stage2};
                        8'h10: s_axil_rdata <= out_data;
                        default: s_axil_rdata <= 64'h0;
                    endcase
                end
                
                READ_DATA: begin
                    s_axil_rvalid <= 1'b1;
                    s_axil_rresp <= 2'b00; // OKAY response
                    
                    if (s_axil_rready) begin
                        s_axil_rvalid <= 1'b0;
                    end
                end
            endcase
            
            // Update output data register using stage 3 pipeline outputs
            if (clk_en_stage2[0]) out_data[15:0] <= output_segment_stage3[0];
            if (clk_en_stage2[1]) out_data[31:16] <= output_segment_stage3[1];
            if (clk_en_stage2[2]) out_data[47:32] <= output_segment_stage3[2];
            if (clk_en_stage2[3]) out_data[63:48] <= output_segment_stage3[3];
        end
    end

endmodule