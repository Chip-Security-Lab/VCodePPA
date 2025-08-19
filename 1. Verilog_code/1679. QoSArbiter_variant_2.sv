//SystemVerilog
module QoSArbiter #(parameter QW=4) (
    input clk, rst_n,
    input [4*QW-1:0] qos,
    input [3:0] req,
    output reg [3:0] grant
);

// Stage 1 signals
reg [QW-1:0] qos_array_stage1 [0:3];
reg [3:0] req_stage1;
reg [QW-1:0] max_qos_stage1;
reg valid_stage1;

// Stage 2 signals
reg [3:0] grant_stage2;
reg valid_stage2;

// Stage 1: Extract QoS values and find max
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_stage1 <= 0;
        req_stage1 <= 0;
        max_qos_stage1 <= 0;
        for (int i = 0; i < 4; i++) begin
            qos_array_stage1[i] <= 0;
        end
    end else begin
        valid_stage1 <= 1;
        req_stage1 <= req;
        for (int i = 0; i < 4; i++) begin
            qos_array_stage1[i] <= qos[i*QW +: QW];
        end
        
        // Find max QoS in stage 1
        max_qos_stage1 <= (qos_array_stage1[0] > qos_array_stage1[1]) ? 
                         ((qos_array_stage1[0] > qos_array_stage1[2]) ? 
                          ((qos_array_stage1[0] > qos_array_stage1[3]) ? qos_array_stage1[0] : qos_array_stage1[3]) : 
                          ((qos_array_stage1[2] > qos_array_stage1[3]) ? qos_array_stage1[2] : qos_array_stage1[3])) : 
                         ((qos_array_stage1[1] > qos_array_stage1[2]) ? 
                          ((qos_array_stage1[1] > qos_array_stage1[3]) ? qos_array_stage1[1] : qos_array_stage1[3]) : 
                          ((qos_array_stage1[2] > qos_array_stage1[3]) ? qos_array_stage1[2] : qos_array_stage1[3]));
    end
end

// Stage 2: Calculate grant
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_stage2 <= 0;
        grant_stage2 <= 0;
    end else if (valid_stage1) begin
        valid_stage2 <= 1;
        grant_stage2 <= req_stage1 & (
            (qos_array_stage1[0]==max_qos_stage1) ? 4'b0001 :
            (qos_array_stage1[1]==max_qos_stage1) ? 4'b0010 :
            (qos_array_stage1[2]==max_qos_stage1) ? 4'b0100 : 4'b1000 );
    end
end

// Output stage
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        grant <= 0;
    else if (valid_stage2)
        grant <= grant_stage2;
end

endmodule