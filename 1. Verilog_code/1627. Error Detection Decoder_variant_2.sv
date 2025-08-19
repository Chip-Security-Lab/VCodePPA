//SystemVerilog
module error_detect_decoder_pipelined (
    input clk,
    input rst_n,
    input valid,
    output reg ready,
    input [3:0] addr,
    output reg [7:0] select,
    output reg error
);

    // Pipeline stage 1 registers
    reg valid_stage1;
    reg [3:0] addr_stage1;
    
    // Pipeline stage 2 registers  
    reg valid_stage2;
    reg [7:0] select_stage2;
    reg error_stage2;

    // State machine registers
    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam PROCESS = 2'b01;
    localparam DONE = 2'b10;

    // Pipeline stage 1: Input sampling
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
            addr_stage1 <= 4'h0;
        end else begin
            valid_stage1 <= valid;
            addr_stage1 <= addr;
        end
    end

    // Pipeline stage 2: Address decoding
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
            select_stage2 <= 8'h00;
            error_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            if (addr_stage1 < 4'h8) begin
                select_stage2 <= (8'h01 << addr_stage1);
                error_stage2 <= 1'b0;
            end else begin
                select_stage2 <= 8'h00;
                error_stage2 <= 1'b1;
            end
        end
    end

    // Output stage: State machine and output control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            ready <= 1'b0;
            select <= 8'h00;
            error <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    ready <= 1'b1;
                    if (valid_stage2) begin
                        state <= PROCESS;
                        ready <= 1'b0;
                    end
                end
                
                PROCESS: begin
                    select <= select_stage2;
                    error <= error_stage2;
                    state <= DONE;
                end
                
                DONE: begin
                    ready <= 1'b1;
                    if (!valid_stage2) begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule