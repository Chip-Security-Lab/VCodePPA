module FSM_Sub (
    // AXI4-Lite Interface
    input wire ACLK,
    input wire ARESETn,
    
    // Write Address Channel
    input wire [31:0] AWADDR,
    input wire AWVALID,
    output reg AWREADY,
    
    // Write Data Channel
    input wire [31:0] WDATA,
    input wire [3:0] WSTRB,
    input wire WVALID,
    output reg WREADY,
    
    // Write Response Channel
    output reg [1:0] BRESP,
    output reg BVALID,
    input wire BREADY,
    
    // Read Address Channel
    input wire [31:0] ARADDR,
    input wire ARVALID,
    output reg ARREADY,
    
    // Read Data Channel
    output reg [31:0] RDATA,
    output reg [1:0] RRESP,
    output reg RVALID,
    input wire RREADY
);

    // Internal registers
    reg [7:0] reg_A_stage1, reg_A_stage2;
    reg [7:0] reg_B_stage1, reg_B_stage2;
    reg [7:0] reg_res_stage1, reg_res_stage2;
    reg reg_done_stage1, reg_done_stage2;
    
    // Write FSM states
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_ADDR = 2'b01;
    localparam WRITE_DATA = 2'b10;
    localparam WRITE_RESP = 2'b11;
    reg [1:0] write_state, write_state_next;
    
    // Read FSM states
    localparam READ_IDLE = 2'b00;
    localparam READ_ADDR = 2'b01;
    localparam READ_DATA = 2'b10;
    reg [1:0] read_state, read_state_next;
    
    // Write FSM
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            write_state <= WRITE_IDLE;
            AWREADY <= 1'b1;
            WREADY <= 1'b0;
            BVALID <= 1'b0;
            BRESP <= 2'b00;
        end else begin
            write_state <= write_state_next;
        end
    end
    
    always @(*) begin
        case (write_state)
            WRITE_IDLE: begin
                if (AWVALID && AWREADY) begin
                    write_state_next = WRITE_ADDR;
                end else begin
                    write_state_next = WRITE_IDLE;
                end
            end
            WRITE_ADDR: begin
                write_state_next = WRITE_DATA;
            end
            WRITE_DATA: begin
                if (WVALID && WREADY) begin
                    write_state_next = WRITE_RESP;
                end else begin
                    write_state_next = WRITE_DATA;
                end
            end
            WRITE_RESP: begin
                if (BREADY) begin
                    write_state_next = WRITE_IDLE;
                end else begin
                    write_state_next = WRITE_RESP;
                end
            end
            default: write_state_next = WRITE_IDLE;
        endcase
    end
    
    always @(posedge ACLK) begin
        case (write_state)
            WRITE_IDLE: begin
                if (AWVALID && AWREADY) begin
                    AWREADY <= 1'b0;
                    WREADY <= 1'b1;
                end
            end
            WRITE_DATA: begin
                if (WVALID && WREADY) begin
                    WREADY <= 1'b0;
                    case (AWADDR[3:0])
                        4'h0: reg_A_stage1 <= WDATA[7:0];
                        4'h4: reg_B_stage1 <= WDATA[7:0];
                    endcase
                    BVALID <= 1'b1;
                end
            end
            WRITE_RESP: begin
                if (BREADY) begin
                    BVALID <= 1'b0;
                    AWREADY <= 1'b1;
                end
            end
        endcase
    end
    
    // Read FSM
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            read_state <= READ_IDLE;
            ARREADY <= 1'b1;
            RVALID <= 1'b0;
            RRESP <= 2'b00;
        end else begin
            read_state <= read_state_next;
        end
    end
    
    always @(*) begin
        case (read_state)
            READ_IDLE: begin
                if (ARVALID && ARREADY) begin
                    read_state_next = READ_ADDR;
                end else begin
                    read_state_next = READ_IDLE;
                end
            end
            READ_ADDR: begin
                read_state_next = READ_DATA;
            end
            READ_DATA: begin
                if (RREADY) begin
                    read_state_next = READ_IDLE;
                end else begin
                    read_state_next = READ_DATA;
                end
            end
            default: read_state_next = READ_IDLE;
        endcase
    end
    
    always @(posedge ACLK) begin
        case (read_state)
            READ_IDLE: begin
                if (ARVALID && ARREADY) begin
                    ARREADY <= 1'b0;
                    RVALID <= 1'b1;
                    case (ARADDR[3:0])
                        4'h0: RDATA <= {24'h0, reg_A_stage2};
                        4'h4: RDATA <= {24'h0, reg_B_stage2};
                        4'h8: RDATA <= {24'h0, reg_res_stage2};
                        4'hC: RDATA <= {31'h0, reg_done_stage2};
                    endcase
                end
            end
            READ_DATA: begin
                if (RREADY) begin
                    RVALID <= 1'b0;
                    ARREADY <= 1'b1;
                end
            end
        endcase
    end
    
    // Core logic with pipelining
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            reg_A_stage2 <= 8'h0;
            reg_B_stage2 <= 8'h0;
            reg_res_stage1 <= 8'h0;
            reg_res_stage2 <= 8'h0;
            reg_done_stage1 <= 1'b0;
            reg_done_stage2 <= 1'b0;
        end else begin
            // Stage 1: Register inputs
            reg_A_stage2 <= reg_A_stage1;
            reg_B_stage2 <= reg_B_stage1;
            
            // Stage 2: Perform subtraction
            reg_res_stage1 <= reg_A_stage2 - reg_B_stage2;
            reg_done_stage1 <= 1'b1;
            
            // Stage 3: Register outputs
            reg_res_stage2 <= reg_res_stage1;
            reg_done_stage2 <= reg_done_stage1;
        end
    end

endmodule